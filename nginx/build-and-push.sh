#!/bin/bash

FULL_IMAGE_NAME="vovan/nginx-ssl:latest"

docker build -t "${FULL_IMAGE_NAME}" .

docker login

docker push "${FULL_IMAGE_NAME}"
