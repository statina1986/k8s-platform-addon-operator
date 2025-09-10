<%! 
import json
import base64
%>

{{- if .Values.cnpgPostgresPlatform }}
{{- $root := . }}
{{- range keys .Values.cnpgPostgresPlatform.clusters  }}
{{- $dbCluster := get $.Values.cnpgPostgresPlatform.clusters . }}
{{- $dbClusterName := . }}

{{- if ne $dbCluster nil }}

{{- $cluster := deepCopy $dbCluster }}
{{- $addonoperator := "${ base64.b64encode(json.dumps(addon_operator).encode('utf-8')).decode('utf-8')}" | b64dec | fromJson }}
{{- $defaultTemplate := tpl $root.Values.cnpgPostgresPlatform.common.defaultClusterTemplate (dict "cluster" $dbCluster "root" $root "addonOperator" $addonoperator "clusterName" .) | fromYaml }}
{{- $cluster := mergeOverwrite ($defaultTemplate | deepCopy) ($root.Values.cnpgPostgresPlatform.common.defaultCluster | default (dict) | deepCopy) $cluster }}

---
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: {{ $dbClusterName }}
  {{- with $cluster.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    app.kubernetes.io/name: {{ $dbClusterName }}
    app.kubernetes.io/instance: {{ $dbClusterName }}
    app.kubernetes.io/part-of: cloudnative-pg
    {{- with $cluster.additionalLabels }}
      {{ toYaml . | nindent 4 }}
    {{- end }}
spec:  
  {{- toYaml $cluster.spec | nindent 2 }}

---
apiVersion: v1
kind: Service
metadata:
  labels:
    cnpg.io/cluster: {{ $dbClusterName }}
  name: {{ $dbClusterName }}
spec:
  internalTrafficPolicy: Cluster
  ports:
  - name: postgres
    port: 5432
    protocol: TCP
    targetPort: 5432
  selector:
    cnpg.io/cluster: {{ $dbClusterName }}
    role: primary
  sessionAffinity: None
  type: ClusterIP

---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $dbClusterName }}-stats-cleanup
spec:
  schedule: "@midnight"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: db-tools
            % if 'containerRegistryBase' in values['global']:
            image: ${values['global']['containerRegistryBase']}/platform/platform-db-tools:1.3.0_202504201254_master_e95ea903
            % else:
            image: platform.artifactory.qvantel.net/platform/platform-db-tools:1.3.0_202504201254_master_e95ea903
            % endif
            imagePullPolicy: IfNotPresent
            env:
              - name: POSTGRES_USER
                valueFrom:
                  secretKeyRef:
                    key: username
                    name: {{ . }}-superuser
              - name: POSTGRES_PASSWORD
                valueFrom:
                  secretKeyRef:
                    key: password
                    name: {{ . }}-superuser
              - name: POSTGRES_SERVICE
                value: "{{.}}"
            command:
            - /bin/sh
            - -c
            - |
              date; echo 'Executing postgresql stats cleanup.'
              PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h $POSTGRES_SERVICE -c \
                "SELECT pg_wait_sampling_reset_profile(); SELECT pg_stat_statements_reset();"\
              && echo 'Postgresql stats cleanup completed.'
          restartPolicy: OnFailure
          backoffLimit: 3
  schedule: "@midnight"

{{- if $cluster.barmanObjectStore }}
---
apiVersion: barmancloud.cnpg.io/v1
kind: ObjectStore
metadata:
  name: {{ $dbClusterName }}-objectstore
spec:
  retentionPolicy: {{ $cluster.barmanObjectStore.retentionPolicy | default "3d" }}
  configuration:
    destinationPath: {{ $cluster.barmanObjectStore.configuration.destinationPath | default "no-path" }}
    endpointURL: {{ $cluster.barmanObjectStore.configuration.endpointURL | default "https://s3.ap-south-1.amazonaws.com" }}
    s3Credentials:
      {{- if $root.Values.cnpgPostgresPlatform.monitoringPlatformEnabled }}
      inheritFromIAMRole: true
      {{- else if hasKey $cluster.barmanObjectStore.configuration.s3Credentials "accessKeyId" }}
      accessKeyId:
        name: {{ $cluster.barmanObjectStore.configuration.s3Credentials.keyName }}
        key: {{ $cluster.barmanObjectStore.configuration.s3Credentials.keyId }}
      secretAccessKey:
        name: {{ $cluster.barmanObjectStore.configuration.s3Credentials.secreName }}
        key: {{ $cluster.barmanObjectStore.configuration.s3Credentials.secreKey }}
      {{- end }}
    wal:
      compression: {{ $cluster.barmanObjectStore.configuration.wal.compression | default "gzip" }}
      maxParallel: {{ $cluster.barmanObjectStore.configuration.wal.maxParallel | default "8" }}
      encryption: {{ $cluster.barmanObjectStore.configuration.wal.encryption | default "AES256" }}
{{- end }}

{{- if $root.Values.cnpgPostgresPlatform.monitoringPlatformEnabled }}
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  labels:
    cnpg.io/cluster: {{ $dbClusterName }}
    release: "{{ $root.Values.global.helmReleaseNamePrefix }}monitoring-platform"
  name: {{ $dbClusterName }}-monitor
spec:
  podMetricsEndpoints:
    - port: metrics
  selector:
    matchLabels:
      cnpg.io/cluster: {{ $dbClusterName }}
{{- end }}

{{- if and $cluster.spec (and $cluster.barmanObjectStore $cluster.barmanObjectStore.scheduledBackup) }}
---
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: {{ $dbClusterName }}-scheduled-backups
spec:
  schedule: {{ $cluster.barmanObjectStore.scheduledBackup }}
  backupOwnerReference: self
  cluster:
    name: {{ $dbClusterName }}
  immediate: true
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
{{- end }}

{{- if and $root.Values.cnpgPostgresPlatform.vaultPlatformEnabled $cluster.vaultConfiguration }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: admin-role-{{ $dbClusterName }}
spec:
  db-name: {{ . }}
  creation-statements: >-
    {{ printf "CREATE USER \"{{name}}\" SUPERUSER PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readonly-role-{{ $dbClusterName }}
spec:
  db-name: {{ . }}
  creation-statements: >-
    {{ printf "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT pg_read_all_data TO \"{{name}}\"" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readwrite-role-{{ $dbClusterName }}
spec:
  db-name: {{ . }}
  creation-statements: >-
    {{ printf "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT pg_read_all_data, pg_write_all_data TO \"{{name}}\"" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbConnection
metadata:
  annotations:
    platform.qvantel.com/retry-count: "100"
  name: {{ $dbClusterName }}
spec:
  connection-name: {{ $dbClusterName }}
  plugin-name: postgresql-database-plugin
  allowed-roles: '*'
  computed-values:
  - expression: k8s_get_secret_value('{{ $dbClusterName }}-superuser','{{ $.Release.Namespace }}','username')
    name: secret-username
  - expression: k8s_get_secret_value('{{ $dbClusterName }}-superuser','{{ $.Release.Namespace }}','password')
    name: secret-password
  db-url: >-
    {{ printf "postgresql://{{username}}:{{password}}@%s.%s.svc:5432/postgres" $dbClusterName $.Release.Namespace }}
  db-username: '{secret-username}'
  db-password: '{secret-password}'

{{- end }}

{{- end }}
{{- end }}
{{- end }}
