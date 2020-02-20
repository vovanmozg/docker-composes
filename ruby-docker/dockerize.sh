#!/bin/bash

git clone https://github.com/vovanmozg/docker-composes.git
cp -r ./docker-composes/ruby-docker/ruby-docker-big/ ./
rm -rf ./docker-composes

echo "Move sources to src directory"
