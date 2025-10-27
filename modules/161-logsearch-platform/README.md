# logsearch-platform module
This module is responsible for deployment of Bitnami ElasticSearch ( LogSearch ).
This module deploys the cluster as a statefulset compared to the operator managed cluster in module [elasticsearch-platform](https://stash.qvantel.net/projects/CP/repos/k8s-platform-addon-operator/browse/modules/160-elasticsearch-platform/README.md)

Depends on modules:
- [vault-platform](https://stash.qvantel.net/projects/CP/repos/k8s-platform-addon-operator/browse/modules/140-vault-platform/README.md) for backing up Kibana readonly credentials to versioned KV2 secrets