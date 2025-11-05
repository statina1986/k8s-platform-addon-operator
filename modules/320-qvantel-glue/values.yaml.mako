qvantelGlue:
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
  cqlinstallersCrdSync:
    # -- Enables CqlInstaller CRDs reconciliation
    enabled: true
    # -- Schedule for periodic reconciliation. Default is "*/5 * * * *" - so every 5 minutes.
    schedule: "*/5 * * * *"
    # -- Selector for namespaces from which sync CqlInstaller resources. Default is `platform` namespace.
    namespaceSelector:
      nameSelector:
        matchNames: [ "${values['global']['platformNamespace']}" ]
  shellinstallersCrdSync:
    # -- Enables ShellInstaller CRDs reconciliation
    enabled: true
    # -- Schedule for periodic reconciliation. Default is "*/5 * * * *" - so every 5 minutes.
    schedule: "*/5 * * * *"
    # -- Selector for namespaces from which sync ShellInstaller resources. Default is `platform` namespace.
    namespaceSelector:
      nameSelector:
        matchNames: [ "${values['global']['platformNamespace']}" ]
  # -- Databases deployment configuration.
  # @default -- see child items docs
  dbs:
    # -- Common configurations to be used across databases 
    # @default -- see child items docs
    common:
      # -- Common configurations for MariaDB databases
      # @default -- see child items docs
      mariadb:
        # -- Default values for MariaDB clusters. See `example-mariadb.cluster` for reference.
        # With this field you can configure common values for all MariaDB clusters, e.g. backup location and schedule.
        defaultCluster: {}
        # -- (tpl/string) Default template for MariaDB clusters. See `example-mariadb.cluster` for reference.
        # This is templated field which is rendered for each cluster from `qvantelGlue.dbs.mariadb`.
        # With this field you can override default cluster template for complex cases and utilize helm templating in it.
        # Scope for the template contains fields: 
        # \newline
        # * addonOperator: content from Addon Operator configmap. You can check if some modules, e.f. monitoring-platform are enabled.
        # \newline
        # * root: root context of 'qvantel-glue' module, containing all Values for the module.
        # \newline
        # * cluster: content of 'cluster' field for rendered cluster.
        # @notationType -- tpl
        defaultClusterTemplate: |+
          {{- if eq $.addonOperator.vaultPlatformEnabled "true" }}
          vaultConfiguration: true
          {{- end }}
          spec:
            {{- if $.root.Values.global.platformMasters }}
            nodeSelector:
              {{ $.root.Values.global.platformMastersKey }}: {{ $.root.Values.global.platformMastersValue }}
            {{- end }}
            storage:
              size: 10Gi
            {{- if eq $.root.Values.global.configurationProfile "dev" }}
            replicas: 1
            {{- else }}
            replicas: 3
            galera:
              enabled: true
              config:
                reuseStorageVolume: true
              providerOptions:
                gcache.size: 128M
            maxScale:
              enabled: true
              replicas: 2
            {{- end }}
            {{- if  eq $.addonOperator.monitoringPlatformEnabled "true"}}
            metrics:
              enabled: true
              serviceMonitor:
                prometheusRelease: "{{ $.root.Values.global.helmReleaseNamePrefix }}monitoring-platform"
            {{- end }}
            affinity:
              antiAffinityEnabled: true  
            tolerations:
              - key: "k8s.mariadb.com/ha"
                operator: "Exists"
                effect: "NoSchedule"
              - key: "{{ $.root.Values.global.platformMastersKey }}"
                value: "{{ $.root.Values.global.platformMastersValue }}"
                operator: "Equal"
                effect: "NoSchedule"
            podDisruptionBudget:
              maxUnavailable: 33%
            updateStrategy:
              type: RollingUpdate
            myCnf: |
              [mariadb]
              bind-address=*
              default_storage_engine=InnoDB
              binlog_format=row
              innodb_autoinc_lock_mode=2
              max_allowed_packet=256M
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
              limits:
                memory: 1Gi  
                
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
          {{- if ne $.root.Values.global.configurationProfile "dev" }}
          barmanObjectStore:
            scheduledBackup: "0 0 0 * * *"
            spec:
              retentionPolicy: "7d"
              configuration:
                s3Credentials:
                  {{- if eq $.addonOperator.awsPlatformEnabled "true" }}
                  inheritFromIAMRole: true
                  {{- end }}
                wal:
                  compression: gzip
                  maxParallel: 8
                  encryption: AES256
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
            {{- if $.cluster.barmanObjectStore }}
            plugins:
            - name: barman-cloud.cloudnative-pg.io
              isWALArchiver: true
              parameters:
                barmanObjectName: {{ $.clusterName }}-objectstore
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
            {{- if eq $.addonOperator.monitoringPlatformEnabled "true" }}
            monitoring:
              podMonitorEnabled: true
              customQueriesConfigMap:
                - name: cnpg-queries-insights-metrics
                  key: custom-metrics-queries
                {{- if and $.cluster.spec $.cluster.spec.postgresql $.cluster.spec.postgresql.parameters (hasKey $.cluster.spec.postgresql.parameters "pg_partman_bgw.dbname") }}
                - name: cnpg-partitions-alerts-{{ $.clusterName }}
                  key: partitions-alerts-queries
                {{- end }}
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
    # For Example, see `example-mariadb` definition in Examples-MariaDB section below.
    mariadb: {}
    # -- Cassandra databases configuration. This is a map where each key corresponds to the K8ssandra cluster 
    # and associated configuration like keyspaces and roles.
    # For Example, see `example-cassandra` definition in Examples-Cassandra section below.
    cassandra: {}
    # -- RabbitMQ vhosts configuration. This is a map where each key corresponds to the dedicated vhost 
    # and associated configuration like roles and permissions.
    # For Example, see `example-rabbitmq` definition in Examples-RabbitMQ section below.
    rabbitmq: {}

# -- This is example PostgreSQL glue definition. 
# In this example CNPG cluster is configured with 3 dbs created in this cluster(`catalog-deployer`, `ddl`, `flex-bpmn-executor`) and few additional roles.
# Note: It is used for documentation purposes only. Real PostgreSQL clusters should be defined under `qvantelGlue.dbs.postgres`
# @section -- Examples-PostgreSQL
example-postgredb:
  # -- Defines CNPG database cluster (kind: Cluster) to deploy. 
  # Values configured in this object are merged with default template from `qvantelGlue.dbs.common.postgres.defaultClusterTemplate` and with default values from `qvantelGlue.dbs.common.postgres.defaultCluster`.
  # Precedence is following defaultClusterTemplate <- defaultCluster <- cluster (values in this object).
  # @default -- null
  # @section -- Examples-PostgreSQL
  cluster:
    # -- Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.
    # @default --  by default equals to 'vaultPlatformEnabled' in addon-operator configmap, so if Vault module is enabled then 'true'
    # @section -- Examples-PostgreSQL
    vaultConfiguration: true
    scheduledBackup: "0 0 0 * * *" # every midnight
    barmanObjectStore:
      # -- Defines scheduled backup configuration as Cron string (e.g. "0 0 0 * * *" - every midnight). If configured, then (kind: ScheduledBackup) will be created for the cluster with provided schedule.
      # @default --  null
      # @section -- Examples-PostgreSQL
      scheduledBackup: "0 0 0 * * *"
      # -- Defines ObjectStore specification. See https://cloudnative-pg.io/plugin-barman-cloud/docs/plugin-barman-cloud.v1/#objectstorespec
      # @default --  null
      # @section -- Examples-PostgreSQL
      spec:
        retentionPolicy: "7d"
        configuration:
          s3Credentials:
            inheritFromIAMRole: true
          wal:
            compression: gzip
            maxParallel: 8
            encryption: AES256
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
  # This is a map where each key corresponds to the Database to be created. If Database name contains hyphens (-) those will be replaced with underscores (_).
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
    mnp-gw:
      # -- Specify namespace for the database. Default Vault roles will be generated with this namespace in mind. When not specified value from `Values.global.appsNamespace` is used.  
      # @default -- null
      # @section -- Examples-PostgreSQL
      namespace: mnp-gw
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

# -- This is example Cassandra glue definition. 
# In this example CNPG cluster is configured with 3 dbs created in this cluster(`catalog-deployer`, `ddl`, `flex-bpmn-executor`) and few additional roles.
# Note: It is used for documentation purposes only. Real PostgreSQL clusters should be defined under `qvantelGlue.dbs.postgres`
# @section -- Examples-Cassandra
example-cassandra:
  # -- Defines K8ssandra cluster (kind: K8ssandraCluster) to deploy. 
  # If it is omitted, no cluster will be deployed as part of `glue` module and it is assumed cluster is deployed externally.
  # @default -- null
  # @section -- Examples-Cassandra
  cluster:
    # -- Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.
    # @default --  by default equals to 'vaultPlatformEnabled' in addon-operator configmap, so if Vault module is enabled then 'true'
    # @section -- Examples-Cassandra
    vaultConfiguration: true
    # -- Configure K8ssandra cluster details. See https://docs.k8ssandra.io/reference/crd/k8ssandra-operator-crds-latest/#k8ssandraclusterspec for API reference.    
    # @default -- null
    # @section -- Examples-Cassandra
    spec: null
  # -- Defines Databases (Keyspaces) to deploy in the K8ssandra Cluster. For each  database `CqlInstaller` is created which will execute Keyspace creation logic according to Qvantel conventions.
  # This is a map where each key corresponds to the Keyspace to be created. If keyspace name contains hyphens (-) those will be replaced with underscores (_).
  # E.g. in the following example `messaging` and `revenue_events` Keyspaces will be created.
  # @default -- {}
  # @section -- Examples-Cassandra
  dbs:
    messaging:
      # -- It is possible to define provisioning CQL for the keyspace if customization is required.
      # @default -- null
      # @section -- Examples-Cassandra
      cql:
        provision: |
          - "CREATE KEYSPACE IF NOT EXISTS messaging WITH replication = {'class':'NetworkTopologyStrategy', 'DC1': 1} AND durable_writes = true;"
          - "ALTER KEYSPACE messaging WITH replication = {'class':'NetworkTopologyStrategy', 'DC1': 1} AND durable_writes = true;"   
    revenue-events:
      cql:
        # -- It is possible to define additional CQL for the keyspace initialization (handy if you want to keep keyspace creation logic default, but still to add something, like additional tables).
        # @default -- null
        # @section -- Examples-Cassandra
        additional:
        - CREATE TABLE IF NOT EXISTS revenue_events.schema_versions ( version int, schema_type text, PRIMARY KEY (version, schema_type) ) WITH CLUSTERING ORDER BY (schema_type DESC);
      # -- Replication configuration for the Keyspace.
      # @default -- {'class':'NetworkTopologyStrategy', 'DC1': 1}
      # @section -- Examples-Cassandra
      replicationFactors: "{'class':'NetworkTopologyStrategy', 'DC1': 1}"
      # -- Configures additional custom roles for this Keyspace in Vault. Keys in this map will be used as Vault roles names.
      # @default -- {}
      # @section -- Examples-Cassandra
      roles:
        apps-another-app-to-access-revenue-events:
          cql: |
            CREATE USER '{{username}}' WITH PASSWORD '{{password}}' NOSUPERUSER; GRANT ALL PERMISSIONS ON KEYSPACE revenue_events TO {{username}};

  # -- Configures additional custom roles for this cluster in Vault. Keys in this map will be used as Vault roles names.
  # @default -- {}
  # @section -- Examples-Cassandra
  roles:
    custom-role-access-all-keyspaces:
      cql: |
        CREATE USER '{{username}}' WITH PASSWORD '{{password}}' NOSUPERUSER; GRANT ALL PERMISSIONS ON ALL KEYSPACES TO {{username}};

  # -- Configures additional CqlInstallers for this cluster. Keys in this map will be used as Vault roles names.
  # @default -- {}
  # @section -- Examples-Cassandra
  cqls:
    migration-tables:
      cql:
      - CREATE TABLE IF NOT EXISTS revenue_events.schema_versions ( version int, schema_type text, PRIMARY KEY (version, schema_type) ) WITH CLUSTERING ORDER BY (schema_type DESC);

# -- This is example MariaDB glue definition. 
# In this example MariaDB cluster is configured with 1 db created in this cluster(`mnp-gw`) and few additional roles.
# Note: It is used for documentation purposes only. Real MariaDB clusters should be defined under `qvantelGlue.db.mariadb`
# @section -- Examples-MariaDB
example-mariadb:
  # -- Defines MariaDB database cluster (kind: MariaDB) to deploy. 
  # Values configured in this object are merged with default template from `qvantelGlue.dbs.common.mariadb.defaultClusterTemplate` and with default values from `qvantelGlue.dbs.common.mariadb.defaultCluster`.
  # Precedence is following defaultClusterTemplate <- defaultCluster <- cluster (values in this object).
  # @default -- null
  # @section -- Examples-MariaDB
  cluster:
    # -- Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.
    # @default --  by default equals to 'vaultPlatformEnabled' in addon-operator configmap, so if Vault module is enabled then 'true'
    # @section -- Examples-MariaDB
    vaultConfiguration: true
    # -- Annotations to be configured on cluster resource.
    # @default --  null
    # @section -- Examples-MariaDB
    annotations: {}
    # -- Additional labels to be configured on cluster resource.
    # @default --  null
    # @section -- Examples-MariaDB
    additionalLabels: {}
    # -- Configure MariaDB cluster details. See https://github.com/mariadb-operator/mariadb-operator/blob/main/docs/api_reference.md#mariadb for API reference.    
    # @default -- {}
    # @section -- Examples-MariaDB
    spec:
      storage:
        size: 1Gi
  # -- Defines Databases to deploy in the MariaDB Cluster. For each  database `SqlInstaller` is created which will execute database creation logic according to Qvantel conventions.  
  # This is a map where each key corresponds to the Database to be created. If Database name contains hyphens (-) those will be replaced with underscores (_).
  # @default -- {}
  # @section -- Examples-MariaDB
  dbs:
    mnp-gw:
      # -- Specify namespace for the database. Default Vault roles will be generated with this namespace in mind. When not specified value from `Values.global.appsNamespace` is used.  
      # @default -- null
      # @section -- Examples-MariaDB
      namespace: mnp
      # -- Additional owners roles to configure in Vault. Each key from this map will be added to Vault with database owner role.
      # @default -- {}
      # @section -- Examples-MariaDB
      owners:
        apps-another-app-to-access-mnp: {}
      sql:
        # -- It is possible to define provisioning SQL for the database if customization is required.
        # @default -- {}
        # @section -- Examples-MariaDB
        provision: |
          - "<custom SQL goes here>"
          - "<custom SQL goes here>"
  # -- Configures additional custom roles for this cluster in Vault. Keys in this map will be used as Vault roles names.
  # @default -- {}
  # @section -- Examples-MariaDB
  roles:
    custom-role-access-multiple-dbs:
      sql: |
        <custom Vault templated SQL goes here>

# -- This is example RabbitMQ glue definition. 
# In this example RabbitMQ cluster is configured with vhost `example-rabbitmq`.
# Note: It is used for documentation purposes only. Real RabbitMQ vhosts should be defined under `qvantelGlue.dbs.rabbitmq`
# @section -- Examples-RabbitMQ
example-rabbitmq:
  # -- Specify namespace for the vhosts roles. Default Vault roles will be generated with this namespace in mind. When not specified value from `Values.global.appsNamespace` is used.  
  # @default -- null
  # @section -- Examples-RabbitMQ
  namespace: mnp
