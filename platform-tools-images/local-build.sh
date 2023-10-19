#!/usr/bin/env bash

timestamp=( `tar -c . | sha1sum` )

docker build -t "local/$1:$timestamp" . --file "./$1.Dockerfile"
docker tag "local/$1:$timestamp" "artifactory.qvantel.net/$1:$timestamp"
docker push "artifactory.qvantel.net/$1:$timestamp"