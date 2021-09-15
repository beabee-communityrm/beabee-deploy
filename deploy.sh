#!/bin/bash

stage="$SSH_ORIGINAL_COMMAND"

(
        if [ "$stage" == "" -o ! -d "/opt/beabee/$stage" ]; then
                echo "Unrecognised stage: $stage"
                exit 1
        fi

        echo "# Deploying stage $stage"

        for app in $(find /opt/beabee/$stage -mindepth 2 -maxdepth 2 -name docker-compose.yml); do
                pushd $(dirname $app)

                echo "## Updating $app"
                date
                docker-compose pull
                DOCKER_BUILDKIT=1 docker-compose build --pull
                docker-compose run --rm --no-deps run npm run typeorm migration:run
                echo "## Restarting $app"
                docker-compose up -d
                docker-compose exec -T router nginx -s reload
                docker-compose exec -T frontend_router nginx -s reload
                echo "## Finished $app"
                date

                popd
        done
) 2>&1 | tee -a /var/log/deploy.log
