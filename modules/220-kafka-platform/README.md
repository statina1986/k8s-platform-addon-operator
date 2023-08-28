# kafka-platform module
This module is responsible for deployment of [Strimzi Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator) in the cluster.

Depends on modules:
- no dependencies

Provides:
- Strimzi Kafka Operator deployment
- Configuration of kafka cluster CRDs (kind: Kafka)
- Kafka UI deployment

## Running in development environments
Current default settings assume High Availability setup with 3 Availability Zones. So it will not run in local development environment with less than 3 Nodes. For local development you might want to change the configuration of the cluster removing affinities and topology spread constraints.