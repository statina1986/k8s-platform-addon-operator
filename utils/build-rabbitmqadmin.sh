#!/usr/bin/env bash
docker buildx build -t platform.artifactory.qvantel.net/platform/rabbitmqadmin-builder:alpine-3.22 --platform linux/arm64,linux/amd64 --push .