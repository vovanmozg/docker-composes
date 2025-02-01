#!/bin/bash
docker compose -f docker-compose.yml -f docker-compose.browser-use.yml stop browser-use
docker compose -f docker-compose.yml -f docker-compose.browser-use.yml up -d
docker compose -f docker-compose.yml -f docker-compose.browser-use.yml exec -it browser-use bash

