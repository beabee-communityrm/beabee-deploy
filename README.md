Very basic server setup with auto deployment for beabee. This is just an
example and it might be missing some steps, if you hit any problems or find
anything confusing raise an issue.

Requirements:

- Docker >= 19.03.8
- Docker Compose: >= 1.28.0
- Postgres: >= 10 (can be installed on any server as long as it's accessible to this one)

### Basic setup

`deploy.sh` assumes instances are in `/opt/beabee/<stage>/<name>`, if you aren't setting
up auto deployment, you can use any location.

Run the following as root, replace `<name>` with a name for your instance. You
also need to create a database somewhere.

```bash
mkdir /opt/beabee/<stage>/<name>
cd /opt/beabee/<stage>/<name>
curl -o docker-compose.yml https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/docker-compose.yml

# Setup config (you need to fill in .env and config.json)
curl -o .env https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/.env.example
mkdir config
curl -o config/config.json https://raw.githubusercontent.com/beabee-communityrm/beabee/master/src/config/example-config.json
chmod 0600 .env

# Somewhere to put uploads (we use an NFS mounted directory)
mkdir -p data/uploads

# Run database migrations
docker-compose run --rm --no-deps run npm run typeorm migration:run

# Start beabee
docker-compose up -d
```

### Auto deployment setup

Run the following as root, replace `<public key>` with a deploy key.

```bash
mkdir -p /opt/beabee

adduser --system --shell /bin/bash deploy

echo 'Defaults:deploy env_keep += "SSH_ORIGINAL_COMMAND"' > /etc/sudoers.d/deploy
echo 'deploy  ALL=(root) NOPASSWD: /home/deploy/deploy.sh' >> /etc/sudoers.d/deploy

su deploy
curl -o /home/deploy/deploy.sh https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/deploy.sh
chmod +x /home/deploy/deploy.sh
mkdir /home/deploy/.ssh
echo -n 'command="sudo /home/deploy/deploy.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty' > /home/deploy/.ssh/authorized_keys
cat <public key> > /home/deploy/.ssh/authorized_keys
```

This creates a user `deploy` who can only run `deploy.sh`, you can use this to
trigger a deploy (e.g. in a GitHub action)
```bash
ssh deploy@<server> <stage>
```
