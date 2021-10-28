#!/bin/bash -e

export DOCKER_BUILDKIT=1

if [ "$#" -gt 0 ]; then
        stage="$1"
        shift
        apps="$@"
else
        stage="$SSH_ORIGINAL_COMMAND"
        apps=""
fi

(
        if [ "$stage" == "" -o ! -d "/opt/beabee/$stage" ]; then
                echo "Unrecognised stage: $stage"
                exit 1
        fi

        echo "# Deploying stage $stage"

        for app_path in $(find /opt/beabee/$stage -mindepth 2 -maxdepth 2 -name docker-compose.yml); do
                app_dir=$(dirname $app_path)
                app=${app_dir/\/opt\/beabee\/$stage\//}

                if [[ $apps != "" && ! $apps =~ $app ]]; then
                        echo "## Ignoring $app"
                        continue
                fi

                echo "## Updating $app"

                pushd $app_dir

                date
                docker-compose pull
                docker-compose build --pull
                docker-compose run --rm --no-deps run npm run typeorm migration:run
                echo "## Restarting $app"
                docker-compose up -d --remove-orphans
                docker-compose exec -T router nginx -s reload
                docker-compose exec -T app_router nginx -s reload
                echo "## Finished updated $app"

                popd
        done

        date
) 2>&1 | tee -a /var/log/deploy.log
