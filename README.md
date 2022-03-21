A basic server setup with optional auto deployment for beabee. If you hit any
problems or find anything confusing please raise an issue, these instructions
are evolving!

Server requirements:

- Docker >= 19.03.8
- Docker Compose: >= 1.28.0

You must also have a PostgreSQL server (>= 10) that is accessible to the server beabee is being installed on


## Basic setup

### 1. Create a database

Run the following on your database server to create beabee's database and user role
```sql
CREATE USER "<user>" WITH PASSWORD '<password>';
CREATE DATABASE "<db>" WITH OWNER "<user>";
\c <db>
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO "<user>";
```

You can choose `<user>`, `<password>` and `<db>`, you will use the following connection string in beabee's configuration:

```
postgresql://<user>:<password>@<host>/<db>
```

### 2. Install beabee

Run the following as root.

```bash
cd <installation directory>

curl -O https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/Dockerfile.frontend
curl -O https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/theme.json

# Setup config (you need to fill in .env)
curl -o .env https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/.env.example
chmod 0600 .env

# Frontend assets (see beabee-frontend)
mkdir -p data/public data/assets

# Run database migrations
docker-compose run --rm --no-deps run npm run typeorm migration:run

# Create beabee container images
docker-compose pull
DOCKER_BUILDKIT=1 docker-compose build --pull

# Start beabee
docker-compose up -d
```

### 3. Configure logging

Docker container logs are sent to syslog by default and assume a syslog daemon
is running on the host server. We use rsyslog with a custom configuration to
store each container's logs in a different file and logrotate to rotate the
logs.

If you want this too, run the following as root.

```bash
curl -o /etc/rsyslog.d/30-docker.conf https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/rsyslog.conf
curl -o /etc/logrotate.d/docker https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/logrotate.conf
```

## Auto deployment setup

> :warning: **NOTE**: The deployment script `deploy.sh` assumes beabee instances are installed in
> `/opt/beabee/<stage>/<name>`

Run the following as root, replace `<public key>` with a deploy key.

```bash
adduser --system --shell /bin/bash deploy

echo 'Defaults:deploy env_keep += "SSH_ORIGINAL_COMMAND"' > /etc/sudoers.d/deploy
echo 'deploy  ALL=(root) NOPASSWD: /opt/beabee/deploy.sh' >> /etc/sudoers.d/deploy

curl -o /opt/beabee/deploy.sh https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/deploy.sh
chmod 0755 /opt/beabee/deploy.sh

su deploy
mkdir /home/deploy/.ssh
echo -n 'command="sudo /opt/beabee/deploy.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty' > /home/deploy/.ssh/authorized_keys
cat <public key> > /home/deploy/.ssh/authorized_keys
```

This creates a user `deploy` who can only run `deploy.sh`, you can use this to
trigger a deploy (e.g. in a GitHub action)
```bash
ssh deploy@<server> <stage>
```

See https://github.com/beabee-communityrm/beabee/blob/master/.github/workflows/deploy.yml for an example
