<%! 
import json
import base64
%>

{{- if .Values.cnpgPostgresPlatform }}
{{- $addonOperator := "${ base64.b64encode(json.dumps(addon_operator).encode('utf-8')).decode('utf-8')}" | b64dec | fromJson }}
{{- $root := . }}
{{- range keys .Values.cnpgPostgresPlatform.clusters  }}
{{- $dbCluster := get $.Values.cnpgPostgresPlatform.clusters . }}
{{- $dbClusterName := . }}

{{- if ne $dbCluster nil }}

{{- $cluster := mergeOverwrite ($root.Values.cnpgPostgresPlatform.common.defaultCluster | default (dict) | deepCopy) (deepCopy $dbCluster) }}
{{- $defaultTemplate := tpl $root.Values.cnpgPostgresPlatform.common.defaultClusterTemplate (dict "cluster" $cluster "root" $root "addonOperator" $addonOperator "clusterName" .) | fromYaml }}
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
  {{- toYaml $cluster.barmanObjectStore.spec | nindent 2 }}
{{- end }}

{{- if eq $addonOperator.monitoringPlatformEnabled "true" }}
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

{{- if and (eq $addonOperator.vaultPlatformEnabled "true") $cluster.vaultConfiguration }}
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
