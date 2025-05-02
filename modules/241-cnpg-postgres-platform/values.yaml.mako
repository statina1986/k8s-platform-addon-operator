cnpgPostgresPlatform:
  monitoringPlatformEnabled: ${addon_operator['monitoringPlatformEnabled']}
  # -- Configuration for CNPG operator helm chart. See https://github.com/cloudnative-pg/charts/tree/main/charts/cloudnative-pg for API reference.
  cloudnative-pg:            
    % if values['global']['deployOperators'] == "true":
    enabled: true
    % else:
    enabled: false
    % endif
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/cloudnative-pg/cloudnative-pg
      % endif
    crds:
      create: false
    % if values['global']['clusterwideResources'] == "false":
    rbac:
      create: false
    config:
      data:
        WATCH_NAMESPACE: ${values['global']['platformNamespace']}
    % endif
    serviceAccount:
      create: false
      name: platform
    additionalEnv:
      # renew certificates 30 days before expiration to avoid alerts in monitoring
      - name: EXPIRING_CHECK_THRESHOLD
        value: "30"
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
  # -- Common configurations for PostgreSQL databases
  # @default -- see child items docs
  common:
    # -- Default values for CNPG clusters. See `example-postgredb` for reference.
    # With this field you can configure common values for all CNPG clusters, e.g. backup location and schedule.
    defaultCluster: {}
    # -- (tpl/string) Default spec for CNPG clusters. See `example-postgredb` for reference.
    # This is templated field which is rendered for each cluster from `cnpgPostgresPlatform.clusters`. 
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

  # -- CNPG clusters configuration. This is a map where each key corresponds to the PostgreSQL cluster to be provisioned
  # For Example, see `example-postgredb` definition in Examples-PostgreSQL section below.
  # By default cluster 'qvt-postgredb' is defined and provisioned with default configuration.
  clusters:
    qvt-postgredb:
      scheduledBackup: "0 0 0 * * *" # every midnight
      vaultConfiguration: false
        
# -- This is example PostgreSQL cluster definition. 
# Note: It is used for documentation purposes only. Real PostgreSQL clusters should be defined under `cnpgPostgresPlatform.clusters`
# Values configured in this object are merged with default template from `cnpgPostgresPlatform.common.defaultClusterTemplate` and with default values from `cnpgPostgresPlatform.common.defaultCluster`.
# Precedence is following defaultClusterTemplate <- defaultCluster <- cluster (values in this object).
# @section -- Examples-PostgreSQL
example-postgredb:
  # -- Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.
  # @default -- by default equals to 'vaultPlatformEnabled' in addon-operator configmap, so if Vault module is enabled then 'true'
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
    backup:
      retentionPolicy: "2d"
      barmanObjectStore:
        destinationPath: "s3://q-sit-pf-postgresql"
    instances: 2
    storage:
      size: 10Gi
    affinity:
      topologyKey: topology.kubernetes.io/zone
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      nodeSelector:
        dedicated-nodes: platform-masters
  