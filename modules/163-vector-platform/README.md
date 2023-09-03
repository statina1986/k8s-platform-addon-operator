
# [Vector](https://vector.dev/) module

Current pipeline configuration:
* Vector agents collects logs from k8s nodes and send them to Vector Aggregator
* Vector Aggregator performs all the logs transformation and filtering
* Vector Aggregator send logs to Loki and optionally to ElasticSearch