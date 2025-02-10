
# [Vector](https://vector.dev/) module

Current pipeline configuration:
* Vector agents collects logs from k8s nodes and send them to Vector Aggregator
* Vector Aggregator performs all the logs transformation and filtering
* Vector Aggregator send logs to Loki and optionally to ElasticSearch

## Deployment Models

Vector Agents are daemonset and allways transfers the logs to Aggregator so there is no effect on its functionality, when deploying, with different configurationProfiles.
Vector Aggregator on the other hand is a statefulset and manages where we send the logs so when deploying, with different configurationProfiles changes are made based on the environment.

globalConfig.configurationProfile values effects explained below:
* dev
    * Endpoint points towards the loki-platform 
* test
    * Endpoint points towards the write-platform
* perf, prod
    * Endpoint points towards the write-platform
    * Replicas 3
    * nodeSelector set to platform-masters