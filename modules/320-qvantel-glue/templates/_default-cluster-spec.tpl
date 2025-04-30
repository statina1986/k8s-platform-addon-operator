{{- define "default-cluster-spec" -}}
spec:
  {{- if or (not $.spec) (not $.spec.imageName) }}
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
      destinationPath: {{ $.root.Values.qvantelGlue.dbs.common.postgres.s3Bucket }}
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
      memory: 1Gi
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
  {{- if or (not $.spec) (not $.spec.bootstrap) }}
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

{{- end }} 