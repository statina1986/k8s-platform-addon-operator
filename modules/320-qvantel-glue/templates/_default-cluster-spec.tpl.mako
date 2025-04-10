{{- define "default-cluster-spec" -}}
spec:
  {{- if or (not $.spec) (not $.spec.imageName) }}
  imageCatalogRef:
    apiGroup: postgresql.cnpg.io
    kind: ClusterImageCatalog
    name: qvantel-base-cnpg-images
    major: 15
  {{- end }}
  enableSuperuserAccess: true
  % if values['global']['configurationProfile'] in {'dev'}: 
  instances: 1
  % else:
  instances: 2
  % endif
  resources:
    requests:
      memory: 1Gi
      cpu: "0.1"
  storage:
    size: 10Gi
  affinity:
    % if values['global']['multiZone']['enabled']:
    topologyKey: topology.kubernetes.io/zone
    % endif
  % if values['global']['configurationProfile'] not in {'dev'}:
  backup:
    retentionPolicy: "7d"
    barmanObjectStore:
      destinationPath: "s3://<your-S3-bucket-name-here>"
      s3Credentials:
        inheritFromIAMRole: true
    wal:
      compression: gzip
      maxParallel: 8
      encryption: AES256
  % endif
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
  % if addon_operator['monitoringPlatformEnabled']:
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
  % endif
  {{- if or (not $.spec) (not $.spec.bootstrap) }}
  bootstrap:
    initdb:
      postInitSQL:
        - "CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;"
        - "CREATE EXTENSION IF NOT EXISTS timescaledb;"
  {{- end }} 
  
  % if 'awsRole' in values['global']:
  serviceAccountTemplate:
    metadata:
      annotations:
        eks.amazonaws.com/role-arn: ${values['global']['awsRole']}
  % endif

{{- end }} 