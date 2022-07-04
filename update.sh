#!/bin/bash -e

export DOCKER_BUILDKIT=1

docker-compose pull
docker-compose build --pull
docker-compose run --rm --no-deps run npm run typeorm migration:run
docker-compose up -d --remove-orphans
docker-compose exec -T router nginx -s reload
docker-compose exec -T app_router nginx -s reload
