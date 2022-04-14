#!/usr/bin/env bash
timestamp=$(date +%Y%m%d%H%M%S)

# Here we build the platform docker image localy as "sashaozz/addon-operator:$timestamp"
docker build -t "kissa555/platform:$timestamp" /mnt/c/Users/hjantti/Documents/work/addon-operator/v4/k8s-platform-addon-operator

# Here we push builded image to dockerhub registry
docker push kissa555/platform:$timestamp

# Here we deploy platform helm chart with custom configuration from  myvalues.yaml
helm upgrade --install k8s-platform -n platform /mnt/c/Users/hjantti/Documents/work/addon-operator/v4/k8s-platform-addon-operator/chart -f myvalues.yaml --set imageVersion=$timestamp
