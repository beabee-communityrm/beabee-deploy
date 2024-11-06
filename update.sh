#!/bin/bash -e

docker compose pull
docker compose run --rm --no-deps run npm run typeorm migration:run
docker compose up -d --remove-orphans
docker compose exec -T app_router nginx -s reload
