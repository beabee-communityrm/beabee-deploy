#!/bin/bash

for app in $(find /opt/beabee -mindepth 2 -maxdepth 2 -name docker-compose.yml); do
        proj=$(basename $(dirname $app))
        dc="docker-compose -f $app -p $proj"

        echo Deploying $proj
        date
        $dc pull
        $dc run --rm --no-deps app npm run typeorm migration:run
        $dc up -d
        echo Finished deploying $proj
        date
done | tee -a deploy.log
