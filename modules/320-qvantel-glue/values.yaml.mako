qvantelGlue:
  monitoringPlatformEnabled: ${addon_operator['monitoringPlatformEnabled']}
  # -- Configuration for SqlInstaller CRDs reconciliation.
  sqlinstallersCrdSync:
    # -- Enables SqlInstaller CRDs reconciliation
    enabled: true
    # -- Schedule for periodic reconciliation. Default is "*/5 * * * *" - so every 5 minutes.
    schedule: "*/5 * * * *"
    # -- Selector for namespaces from which sync SqlInstaller resources. Default is `platform` namespace.
    namespaceSelector:
      nameSelector:
        matchNames: [ "${values['global']['platformNamespace']}" ]
  # -- Databases deployment configuration.
  dbs:
    # -- PostgreSQL databases configuration. This is a map where each key corresponds to the PostgreSQL cluster 
    # and associated configuration like dbs, roles and extensions.
    # For Example, see `example-postgredb` definition in Examples-PostgreSQL section below.
    postgres: {}
    # -- MariaDB databases configuration. This is a map where each key corresponds to the MariaDB cluster 
    # and associated configuration like dbs, roles and extensions.
    mariadb: {}
    # -- Cassandra databases configuration. This is a map where each key corresponds to the K8ssandra cluster 
    # and associated configuration like keyspaces and roles.
    cassandra: {}

# -- This is example PostgreSQL glue definition. 
# Note: It is used for documentation purposes only. Real PostgreSQL clusters should be defined under `qvantelGlue.dbs.postgres`
# @section -- Examples-PostgreSQL
example-postgredb:
  # -- Defines CNPG database cluster (kind: Cluster) to deploy. 
  # If it is omitted, no cluster will be deployed as part of `glue` module and it is assumed cluster is deployed externally.
  # Cluster configuration follows same structure which is deinfed in [cnpg-postgres-platform](/modules/241-cnpg-postgres-platform/README.md) module.
  # In this example CNPG cluster is configured with 3 dbs created in this cluster(`catalog-deployer`, `ddl`, `flex-bpmn-executor`) and few additional roles.
  # @default -- null
  # @section -- Examples-PostgreSQL
  cluster:
    # -- Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.
    # @default --  false
    # @section -- Examples-PostgreSQL
    vaultConfiguration: true
    # -- Configure CNPG cluster details. See https://cloudnative-pg.io/documentation/current/cloudnative-pg.v1/#postgresql-cnpg-io-v1-ClusterSpec for API reference.
    # Values configured in this spec are merged with result of templating [_default-cluster-spec.tpl.mako](templates/_default-cluster-spec.tpl.mako).
    # @default -- {}
    # @section -- Examples-PostgreSQL
    spec:
      affinity:
        topologyKey: topology.kubernetes.io/zone
      instances: 2
      enableSuperuserAccess: true
      imageName: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:15.7-1_7_master_b0ee48eda
      postgresql:
        parameters:
          pg_stat_statements.max: "10000"
          pg_stat_statements.track: all
          max_connections: "300"
          wal_compression: pglz
          random_page_cost: "1"
        shared_preload_libraries:
        - timescaledb
      resources:
        requests:
          memory: 1Gi
          cpu: "0.1"
      storage:
        size: 10Gi
  # -- Defines Databases to deploy in the CNPG Cluster. For each  database `SqlInstaller` is created which will execute database creation logic according to Qvnatel conventions.   
  # @default -- {}
  # @section -- Examples-PostgreSQL
  dbs:
    catalog-deployer:
      sql:
        # -- It is possible to define provisionsing SQL for the database if customization is required.
        # @default -- {}
        # @section -- Examples-PostgreSQL
        provision: |
          - "CREATE ROLE db_catalog_deployer NOLOGIN"
          - "GRANT db_catalog_deployer TO CURRENT_USER"
          - "CREATE DATABASE catalog_deployer WITH OWNER db_catalog_deployer"    
    ddl:
      # -- Configures PostgreSQL extensions for database. Currently only `timescaledb` is supported.
      # @default -- null
      # @section -- Examples-PostgreSQL
      extensions:
        # -- Enables `timescaledb` extensions for database.
        # @default -- {}
        # @section -- Examples-PostgreSQL
        timescaledb: {}
    flex-bpmn-executor:
      # -- Additional owners roles to configure in Vault. Each key from this map will be added to Vault with database owner role.
      # @default -- {}
      # @section -- Examples-PostgreSQL
      owners:
        apps-another-app-to-access-flex: {}
  # -- Configures additional custom roles for this cluster in Vault. Keys in this map will be used as Vault roles names.
  # @default -- {}
  # @section -- Examples-PostgreSQL
  roles:
    custom-role-access-multiple-dbs:
      sql: |
        CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
        GRANT db_ddl TO "{{name}}";
        GRANT db_flex_bpmn_executor TO "{{name}}";
        ALTER ROLE "{{name}}" SET role db_ddl;
        ALTER ROLE "{{name}}" SET role db_flex_bpmn_executor;
