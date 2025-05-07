# A guide to self-hosting beabee

**Any questions?** Raise an issue or email tech@beabee.io. We will do our best to help but we are a very small team so can't offer any formal support.

Please note that beabee is currently in the early stages of development, as such this setup is likely to change in the future. We will offer guidance where possible when we make significant changes, if you want to be kept informed please let us know you are self-hosting beabee at tech@beabee.io.

## Basic setup

Server requirements:

- Docker >= 19.03.8
- Docker Compose >= 2

You must also have a PostgreSQL server (>= 13) that is accessible to the server beabee is being installed on

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

# Get the files (you need to fill in .env)
curl -O https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/update.sh
curl -o .env https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/.env.example
chmod 0600 .env
chmod 0700 update.sh

# Persistent location to store file uploads
mkdir -p data/uploads

# Install everything
./update.sh

# Do some initial configuration
docker compose run --rm tun yarn backend-cli configure --emailDomain <example.com>

# Create a first user to login with
docker compose run --rm tun yarn backend-cli user create --firstname <YourFirstname> --lastname <YourLastname> --email <YourEmail> --password <YourPassword>
```

### 3. Optional: configure logging

Docker container logs are sent to syslog by default and assume a syslog daemon
is running on the host server. We use rsyslog with a custom configuration to
store each container's logs in a different file and logrotate to rotate the
logs.

If you want this too, run the following as root.

```bash
curl -o /etc/rsyslog.d/30-docker.conf https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/rsyslog.conf
curl -o /etc/logrotate.d/docker https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/logrotate.conf
```

### 4. File Storage: MinIO

beabee uses MinIO for file storage. The MinIO service is automatically configured in the docker-compose.yml file.

By default, MinIO uses these credentials:
- Username: minioadmin
- Password: minioadmin

For production environments, we strongly recommend changing these defaults by setting the following environment variables in your .env file:
```
BEABEE_MINIO_ROOT_USER=your_custom_username
BEABEE_MINIO_ROOT_PASSWORD=your_secure_password
```

### 5. Updating

To update simply navigate to your beabee install and run the script
```bash
cd <installation directory>
./update.sh
```

#### Migrating from PictShare

If you're upgrading from a previous version that used PictShare for file storage, you'll need to migrate your uploads to MinIO. Run the following command:

```bash
# Mount your old PictShare uploads volume
docker-compose exec api_app yarn backend-cli migrate-uploads --source=/old_data
```

## Auto deployment setup

Run the following as root, replace `<public key>` with a deploy key.

**NOTE**: The deployment script `deploy.sh` assumes beabee instances are installed in
`/opt/beabee/<stage>/<name>`

```bash
adduser --system --shell /bin/bash deploy

echo 'Defaults:deploy env_keep += "SSH_ORIGINAL_COMMAND"' > /etc/sudoers.d/deploy
echo 'deploy  ALL=(root) NOPASSWD: /opt/beabee/deploy.sh' >> /etc/sudoers.d/deploy

curl -o /opt/beabee/update.sh https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/update.sh
curl -o /opt/beabee/deploy.sh https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/deploy.sh
chmod 0755 /opt/beabee/deploy.sh /opt/beabee/update.sh

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

## Note: Future CLI Integration

This deployment repository will soon be integrated into the main beabee monorepo. Future versions will provide a streamlined installation process using an NPX-runnable CLI tool. Stay tuned for updates.
