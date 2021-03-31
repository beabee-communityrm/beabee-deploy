Very basic server setup with auto deployment for beabee. This is just an
example and it might be missing some steps, if you hit any problems or find
anything confusing raise an issue.

### Basic setup

Requirements:
- Docker >= 19.03.8
- Docker Compose: >= 1.28.0
- Postgres: >= 10 (can be installed on any server as long as it's accessible to this one)

Run the following as root, replace `<private key>` with a deploy key.

```bash
mkdir -p /opt/beabee

adduser deploy
curl -o /home/deploy/deploy.sh https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/deploy.sh
echo 'deploy  ALL=(root) NOPASSWD: /home/deploy/deploy.sh' > /etc/sudoers.d/deploy
cat > /home/deploy/.ssh/authorized_keys <<EOF
command="sudo /home/deploy/deploy.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty <private key>
EOF
```

This creates a user `deploy` who can only run `deploy.sh`, you can use this to
trigger a deploy (e.g. in a GitHub action)
```bash
ssh deploy@<server> deploy
```

### Add an instance

`deploy.sh` assumes instances are in `/opt/beabee/<name>`

Run the following as root, replace `<name>` with a name for your instance. You
also need to create a database somewhere.

```bash
mkdir /opt/beabee/<name>
cd /opt/beabee/<name>
curl -o docker-compose.yml https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/docker-compose.yml

# Setup config (you need to fill in .env and config.json)
curl -o .env https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/.env.example
mkdir config
curl -o config/config.json https://raw.githubusercontent.com/beabee-communityrm/beabee/master/src/config/example-config.json
chmod 0600 .env config/config.json

# Somewhere to put uploads (we use an NFS mounted directory)
mkdir -p data/uploads

# Run database migrations
docker-compose run --rm --no-deps app npm run typeorm migration:run

# Start beabee
docker-compose up -d
```
