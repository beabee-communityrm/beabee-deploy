Very basic server setup with optional auto deployment for beabee. If you hit any
problems or find anything confusing please raise an issue, these instructions
are evolving!

Requirements:

- Docker >= 19.03.8
- Docker Compose: >= 1.28.0
- Postgres: >= 10 (can be installed on any server as long as it's accessible to this one)

## Basic setup

Run the following as root.

```bash
cd <installation directory>

curl -O https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/Dockerfile.frontend

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

### Logging

Docker container logs are sent to syslog by default and assume a syslog daemon
is running on the host server. We use rsyslog with a custom configuration to
store each container's logs in a different file and logrotate to rotate the
logs.

If you want this too, run the following as root.

```bash
wget -o /etc/rsyslog.d/30-docker.conf https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/rsyslog.conf
wget -o /etc/logrotate.d/docker https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/logrotate.conf
```

## Auto deployment setup

> :warning: **NOTE**: The deployment script `deploy.sh` assumes instances are created in
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
