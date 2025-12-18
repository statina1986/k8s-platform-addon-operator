# CHANGELOG

## 1.3.0 (WIP)

### New Features
* Postgres 18 and Timescale 2.23.1 support. Postgres 18 is default version for the CNPG clusters.
* Kafka 3.9.1 and KRaft support.
* Velero Backup for Kubernetes resources and PVs.
* Vault support dynamic credentials for Redis, RabbitMQ.
* OpenTelemetry support. Platform is capable to run OTel collectors and configure OTel auto-instrumentation for applications within cluster.
* Distributed Traces support with Grafana Tempo backend.
* MariaDB Advanced monitoring and Queries Analyzers.
* MariaDB MaxScale, Galera, Replication HA support.
* OpenSearch support.
* Qvantel Glue supports managing of DBs definitions for PostgreSQL, MariaDB, Cassandra, RabbitMQ according to Qvantel Conventions.
* CoreDNS deployments and configurability support.
* MetalLB support.
* Scaledown operator deployment and improved scaleup/scaledown procedure on AWS.
* Redis is now configured with support for single load-balanced ClusterIP endpoint (`redis-platform-master`). This allows applications without Sentinel support or External application outside of K8s cluster to use HA Redis platform service. Direct use of Sentinels is still recommended approach within cluster as it provides faster switchover. 
* Most of the modules are upgraded to newer stable versions of packages and helm-charts
* Bitnami OSS catalog closure related changes: images references are moved to bitnami-legacy repo and charts are updated to latests available version.

### Changes affecting applications running on top of the Platform
* Redis is configured with Dynamic Vault credentials. Static shared redis credentials are deprecated and planned to be disabled by default in future releases. Applications should start migrating to Dynamic Vault credentials and should start using `readwrite-role-redis-platform` role. 
* RabbitMQ is configured with Dynamic Vault credentials. Static shared RabbitMQ credentials are deprecated and should be used only for legacy workloads not integrated with Vault.
* RabbitMQ is configured to use virtual hosts isolation. Each dedicated application/domain should use it's own virtual host. E.g. RBS is supposed to be using "/rbs" vhost, not "/". 
* RabbitMQ default admin username is changed to be `admin`. It will be accessible only within `platform` namespace.
* Consul syncing methods have changed. Applications Services (from apps namespace) are synced to Consul as individual (headless) IPs as previously. Platform services are synced to Consul as ClusterIPs.
* Consul DNS is deprecated and disabled by default.

### Major changes, deprecations, and removals
* Kafka module is upgraded to Strimzi 0.45.0. It is the latest Strimzi version which supports both Zookeeper and KRaft. Deployments which are using Kafka will need to upgrade to KRaft, because in the future version it will be only available method. See detailed steps in the migration guide.
* Zalando based Postgres module (`240-postgres-platform`) was removed. CNPG based Postgres (`241-cnpg-postgres-platform`) should be used everywhere instead.
* CNPG clusters definitions were removed from `241-cnpg-postgres-platform` module completely. `320-qvantel-glue` module should be used to provision clusters and DBs. All cluster definitions should be migrated to `320-qvantel-glue` module with proper helm ownership change. See [KPLAT-453](https://qvantel.atlassian.net/browse/KPLAT-453) for details.
* MariaDB clusters definitions were removed from `251-mariadb-operator-platform` module completely. `320-qvantel-glue` module should be used to provision clusters and DBs. All cluster definitions should be migrated to `320-qvantel-glue` module with proper helm ownership change. See [KPLAT-460](https://qvantel.atlassian.net/browse/KPLAT-460) for details.
* MariaDB default cluster definitions were updated to be Galera cluster with max-scale by default. This is the main setup for now which support fully tested HA.
* Cassandra clusters definitions were removed from `211-kasope-platform` module completely. `320-qvantel-glue` module should be used to provision clusters and DBs. All cluster definitions should be migrated to `320-qvantel-glue` module with proper helm ownership change.
* Vault Webhook configuration has changed. There is no more additional webhook for "platform" namespace, instead `namespaceSelector` of `vault-secrets-webhook` should be used to configure namespace selector of common vault secrets webhook. If your deployments have custom `namespaceSelector` then you might want to double-check it and add "platform" namespace there.
* Postgres 18 is the default CNPG version now. Make sure that existing clusters will have current PG version pinned, or properly migrated to new version. 
