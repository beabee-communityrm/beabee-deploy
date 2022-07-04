# A guide to self-hosting beabee

**Any questions?** Raise an issue or email tech@beabee.io. We will do our best to help but we are a very small team so can't offer any formal support.

Please note that beabee is currently in the early stages of development, as such this setup is likely to change in the future. We will offer guidance where possible when we make significant changes, if you want to be kept informed please let us know you are self-hosting beabee at tech@beabee.io.

## Basic setup

Server requirements:

- Docker >= 19.03.8
- Docker Compose: >= 1.28.0

You must also have a PostgreSQL server (>= 10) that is accessible to the server beabee is being installed on

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

# Frontend theming (see below)
mkdir -p data/public data/assets

# Run database migrations
docker-compose run --rm --no-deps run npm run typeorm migration:run

# Create beabee container images
docker-compose pull
DOCKER_BUILDKIT=1 docker-compose build --pull

# Start beabee
docker-compose up -d

# Create a first user to login with
docker-compose run --rm run node built/tools/new-user
```

### 3. Optional: Customise beabee's theme

beabee's theme is customisable so it can match your site's identity.

To apply changes to the theme you must rebuild and restart the Docker
containers, you can use the update script
```
./update.sh
```

#### Logo and favicon

Put your logo in `./data/assets/images/logo.png`, it should have a square aspect ratio (1:1)

Use https://realfavicongenerator.net/ to generate your favicon assets and put the files in `./data/public`

#### Colours

Set the colours in `./theme.json`. The `primary` and `link` colours are required, all other are optional.

* `primary`: Used to for lots of things, makes the app feel like yours!
* `link`: Used for links and other navigational elements (use same as `primary` if unsure)
* `body`: defaults to primary, the colour of body text
* `warning`: warning notifications
* `success`: success messages and notifications
* `danger`: errors and highlighting dangerous actions
* `white`: white
* `black`: black

#### Fonts

You can customise a `title` and `body` font.

1. Put your font files in `./data/assets/fonts`
2. Create a stylesheet with `@font-face` declarations in `./data/assets/styles/fonts.css`

  Here is an example `font.css` file
  ```css
  @font-face {
    font-family: "Fira Sans Condensed";
    src: url("../fonts/FiraSansCondensed-Bold.woff2") format("woff2"),
      url("../fonts/FiraSansCondensed-Bold.woff") format("woff");
    font-weight: 700;
    font-style: normal;
  }

  @font-face {
    font-family: "Fira Sans Condensed";
    src: url("../fonts/FiraSansCondensed-Regular.woff2")
        format("woff2"),
      url("../fonts/FiraSansCondensed-Regular.woff") format("woff");
    font-weight: 400;
    font-style: normal;
  }

  @font-face {
    font-family: "Fira Sans Condensed";
    src: url("../fonts/FiraSansCondensed-SemiBold.woff2")
      format("woff2");
    font-weight: 600;
    font-style: normal;
  }
  ```
3. Set the fonts in `./theme.json`



### 4. Optional: configure logging

Docker container logs are sent to syslog by default and assume a syslog daemon
is running on the host server. We use rsyslog with a custom configuration to
store each container's logs in a different file and logrotate to rotate the
logs.

If you want this too, run the following as root.

```bash
curl -o /etc/rsyslog.d/30-docker.conf https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/rsyslog.conf
curl -o /etc/logrotate.d/docker https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/logrotate.conf
```

### 5. Updating

To get the latest version of beabee you can use the provided update script. You can store it anywhere but
we recommend you store it in the same directory as your beabee install
```bash
curl https://raw.githubusercontent.com/beabee-communityrm/beabee-deploy/main/update.sh
chmod 0755 ./update.sh
```

To update simply navigate to your beabee install and run the script
```bash
cd <installation directory>
./update.sh
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
