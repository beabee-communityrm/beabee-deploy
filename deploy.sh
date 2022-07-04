#!/bin/bash -e

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
                /opt/beabee/update.sh

                echo "## Finished updated $app"
                popd
        done

        date
) 2>&1 | tee -a /var/log/deploy.log
