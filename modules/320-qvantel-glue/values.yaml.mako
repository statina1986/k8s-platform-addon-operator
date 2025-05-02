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
  # @default -- see child items docs
  dbs:
    # -- Common configurations to be used across databases 
    # @default -- see child items docs
    common:
      # -- Common configurations for PostgreSQL databases
      # @default -- see child items docs
      postgres:
        # -- Default values for CNPG clusters. See `example-postgredb.cluster` for reference.
        # With this field you can configure common values for all CNPG clusters, e.g. backup location and schedule.
        defaultCluster: {}
        # -- (tpl/string) Default template for CNPG clusters. See `example-postgredb.cluster` for reference.
        # This is templated field which is rendered for each cluster from `qvantelGlue.dbs.postgres`.
        # With this field you can override default cluster template for complex cases and utilize helm templating in it.
        # Scope for the template contains fields: 
        # \newline
        # * addonOperator: content from Addon Operator configmap. You can check if some modules, e.f. monitoring-platform are enabled.
        # \newline
        # * root: root context of 'qvantel-glue' module, containing all Values for the module.
        # \newline
        # * cluster: content of 'cluster' field for rendered cluster.
        # @notationType -- tpl
        defaultClusterTemplate: |
          {{- if eq $.addonOperator.vaultPlatformEnabled "true" }}
          vaultConfiguration: true
          {{- end }}
          spec:
            {{- if or (not $.cluster.spec) (not $.cluster.spec.imageName) }}
            imageCatalogRef:
              apiGroup: postgresql.cnpg.io
              kind: ImageCatalog
              name: qvantel-base-cnpg-images
              major: 15
            {{- end }}
            enableSuperuserAccess: true
            {{- if eq $.root.Values.global.configurationProfile "dev" }}
            instances: 1
            {{- else }}
            instances: 2
            {{- end }}
            affinity:
              {{- if $.root.Values.global.multiZone.enabled }}
              topologyKey: topology.kubernetes.io/zone
              {{- end }}
            {{- if ne $.root.Values.global.configurationProfile "dev" }}
            backup:
              retentionPolicy: "7d"
              barmanObjectStore:
                destinationPath: "s3://s3-bucket-for-postgresql"
                s3Credentials:
                {{- if $.addonOperator.monitoringPlatformEnabled }}
                  inheritFromIAMRole: true
                {{- end }}
              wal:
                compression: gzip
                maxParallel: 8
                encryption: AES256
            {{- end }}
            postgresql:
              parameters:
                auto_explain.log_min_duration: "500ms"
                auto_explain.log_analyze: "on"
                auto_explain.log_timing: "off"
                max_connections: "500"      
                random_page_cost: "1"
                pg_stat_statements.max: "10000"
                pg_stat_statements.track: "top"
                pg_stat_statements.track_utility: "off"
                pg_wait_sampling.profile_pid: "false"
                track_io_timing: "on"
                wal_compression: "pglz"
              shared_preload_libraries:
                - timescaledb
                - pg_partman_bgw
                - pg_wait_sampling
                {{- if $.additionalSharedLibraries }}
                {{- range $.additionalSharedLibraries }}
                - {{ . }}
                {{- end }}
                {{- end }}
            resources:
              requests:
                cpu: "0.1"
            storage:
              size: 10Gi
            {{- if $.addonOperator.monitoringPlatformEnabled }}
            monitoring:
              podMonitorEnabled: true
              customQueriesConfigMap:
                - name: cnpg-queries-insights-metrics
                  key: custom-metrics-queries
                {{- if $.additionalCustomQueriesConfigMaps }}
                {{- range $k, $v := $.additionalCustomQueriesConfigMaps }}
                - name: {{ $k }}
                {{ $v | toYaml | indent 2 }}
                {{- end }}
                {{- end }}
            {{- end }}
            {{- if or (not $.cluster.spec) (not $.cluster.spec.bootstrap) }}
            bootstrap:
              initdb:
                postInitSQL:
                  - "CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;"
                  - "CREATE EXTENSION IF NOT EXISTS timescaledb;"
            {{- end }}
            {{- if $.root.Values.global.awsRole }}
            serviceAccountTemplate:
              metadata:
                annotations:
                  eks.amazonaws.com/role-arn: {{ $.root.Values.global.awsRole }}
            {{- end }}

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
# In this example CNPG cluster is configured with 3 dbs created in this cluster(`catalog-deployer`, `ddl`, `flex-bpmn-executor`) and few additional roles.
# Note: It is used for documentation purposes only. Real PostgreSQL clusters should be defined under `qvantelGlue.dbs.postgres`
# @section -- Examples-PostgreSQL
example-postgredb:
  # -- Defines CNPG database cluster (kind: Cluster) to deploy. 
  # If it is omitted, no cluster will be deployed as part of `glue` module and it is assumed cluster is deployed externally.
  # Values configured in this object are merged with default template from `qvantelGlue.dbs.common.postgres.defaultClusterTemplate` and with default values from `qvantelGlue.dbs.common.postgres.defaultCluster`.
  # Precedence is following defaultClusterTemplate <- defaultCluster <- cluster (values in this object).
  # Cluster configuration follows same structure which is defined in [cnpg-postgres-platform](/modules/241-cnpg-postgres-platform/README.md) module. 
  # @default -- null
  # @section -- Examples-PostgreSQL
  cluster:
    # -- Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.
    # @default --  by default equals to 'vaultPlatformEnabled' in addon-operator configmap, so if Vault module is enabled then 'true'
    # @section -- Examples-PostgreSQL
    vaultConfiguration: true
    # -- Defines scheduled backup configuration as Cron string (e.g. "0 0 0 * * *" - every midnight). If configured, then (kind: ScheduledBackup) will be created for the cluster with provided schedule.
    # @default --  null
    # @section -- Examples-PostgreSQL
    scheduledBackup: "0 0 0 * * *" # every midnight
    # -- Annotations to be configured on cluster resource.
    # @default --  null
    # @section -- Examples-PostgreSQL
    annotations: {}
    # -- Additional labels to be configured on cluster resource.
    # @default --  null
    # @section -- Examples-PostgreSQL
    additionalLabels: {}
    # -- Configure CNPG cluster details. See https://cloudnative-pg.io/documentation/current/cloudnative-pg.v1/#postgresql-cnpg-io-v1-ClusterSpec for API reference.    
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
  # -- Defines Databases to deploy in the CNPG Cluster. For each  database `SqlInstaller` is created which will execute database creation logic according to Qvantel conventions.   
  # @default -- {}
  # @section -- Examples-PostgreSQL
  dbs:
    catalog-deployer:
      sql:
        # -- It is possible to define provisioning SQL for the database if customization is required.
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
