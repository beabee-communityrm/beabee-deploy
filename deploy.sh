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
                docker-compose run --rm --no-deps app npm run typeorm migration:run
                echo "## Restarting $app"
                docker-compose up -d
                echo "## Finished $app"
                date

                popd
        done
) 2>&1 | tee -a /var/log/deploy.log
