# CHANGELOG

## 1.3.0 (WIP)

* Most of the modules are upgraded to latest stable versions of packages and helm-charts
* Bitnami OSS catalog closure related changes: images references are moved to bitnami-legacy repo and charts are updated to latests available version.

### Major changes, deprecations, and removals

* Kafka module is upgraded to Strimzi 0.45.0. It is the latest Strimzi version which supports both Zookeeper and KRaft. Deployments which are using Kafka will need to upgrade to KRaft, because in the future version it will be only available method. See detailed steps in the migration guide.
* Zalando based Postgres module (`240-postgres-platform`) was removed. CNPG based Postgres (`241-cnpg-postgres-platform`) should be used everywhere instead.