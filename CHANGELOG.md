# CHANGELOG

## 1.3.0 (WIP)

* Redis is now configured with support for single load-balanced ClusterIP endpoint (`redis-platform-master`). This allows applications without Sentinel support or External application outside of K8s cluster to use HA Redis platform service. Direct use of Sentinels is still recommended approach within cluster as it provides faster switchover. 
* Most of the modules are upgraded to latest stable versions of packages and helm-charts
* Bitnami OSS catalog closure related changes: images references are moved to bitnami-legacy repo and charts are updated to latests available version.


### Changes affecting applications running on top of the Platform
* Redis is configured with Dynamic Vault credentials. Static shared redis credentials are deprecated and planned to be disabled by default n future releases. Applications should start migrating to Dynamic Vault credentials and should start using `readwrite-role-redis-platform` role. 

### Major changes, deprecations, and removals

* Kafka module is upgraded to Strimzi 0.45.0. It is the latest Strimzi version which supports both Zookeeper and KRaft. Deployments which are using Kafka will need to upgrade to KRaft, because in the future version it will be only available method. See detailed steps in the migration guide.
* Zalando based Postgres module (`240-postgres-platform`) was removed. CNPG based Postgres (`241-cnpg-postgres-platform`) should be used everywhere instead.
* CNPG clusters definitions were removed from `241-cnpg-postgres-platform` module completely. `320-qvantel-glue` module should be used to provision clusters and DBs. All cluster definitions should be migrated to `320-qvantel-glue` module with proper helm ownership change. See [KPLAT-453](https://qvantel.atlassian.net/browse/KPLAT-453) for details.


