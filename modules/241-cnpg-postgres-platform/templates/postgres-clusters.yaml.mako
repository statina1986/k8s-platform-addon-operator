<%! 
import json
import base64
%>

{{- if .Values.cnpgPostgresPlatform }}
{{- $root := . }}
{{- range keys .Values.cnpgPostgresPlatform.clusters  }}
{{- $current := get $.Values.cnpgPostgresPlatform.clusters . }}

{{- if ne $current nil }}

{{- $cluster := deepCopy $current }}
{{- $addonoperator := "${ base64.b64encode(json.dumps(addon_operator).encode('utf-8')).decode('utf-8')}" | b64dec | fromJson }}
{{- $defaultTemplate := tpl $root.Values.cnpgPostgresPlatform.common.defaultClusterTemplate (dict "cluster" $current "root" $root "addonOperator" $addonoperator) | fromYaml }}
{{- $current := mergeOverwrite $defaultTemplate ($root.Values.cnpgPostgresPlatform.common.defaultCluster | default (dict)) $cluster }}

---
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: {{ . }}
  {{- with $current.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    app.kubernetes.io/name: {{ . }}
    app.kubernetes.io/instance: {{ . }}
    app.kubernetes.io/part-of: cloudnative-pg
  {{- with $current.additionalLabels }}
    {{ toYaml . | nindent 4 }}
  {{- end }}
spec:  
  {{- toYaml $current.spec | nindent 2 }}

---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ . }}-stats-cleanup
spec:
  schedule: "@midnight"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: db-tools
            image: platform.artifactory.qvantel.net/platform/platform-db-tools:1.3.0_202504201254_master_e95ea903
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

{{- if $root.Values.cnpgPostgresPlatform.monitoringPlatformEnabled }}
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  labels:
    cnpg.io/cluster: {{ . }}
    release: "{{ $root.Values.global.helmReleaseNamePrefix }}monitoring-platform"
  name: {{ . }}-monitor
spec:
  podMetricsEndpoints:
    - port: metrics
  selector:
    matchLabels:
      cnpg.io/cluster: {{ . }}
{{- end }}


{{- if and $current.spec (and $current.spec.backup $current.scheduledBackup) }}
---
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: {{ . }}-scheduled-backups
spec:
  schedule: {{ $current.scheduledBackup }}
  backupOwnerReference: self
  cluster:
    name: {{ . }}
  immediate: true
  target: {{ $current.spec.backup.target | default "prefer-standby" }}
{{- end }}

{{- if $current.vaultConfiguration }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: admin-role-{{ . }}
spec:
  db-name: {{ . }}
  creation-statements: >-
    {{ printf "CREATE USER \"{{name}}\" SUPERUSER PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readonly-role-{{ . }}
spec:
  db-name: {{ . }}
  creation-statements: >-
    {{ printf "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT pg_read_all_data TO \"{{name}}\"" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readwrite-role-{{ . }}
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
  name: {{ . }}
spec:
  connection-name: {{ . }}
  plugin-name: postgresql-database-plugin
  allowed-roles: '*'
  computed-values:
  - expression: k8s_get_secret_value('{{ . }}-superuser','{{ $.Release.Namespace }}','username')
    name: secret-username
  - expression: k8s_get_secret_value('{{ . }}-superuser','{{ $.Release.Namespace }}','password')
    name: secret-password
  db-url: >-
    {{ printf "postgresql://{{username}}:{{password}}@%s.%s.svc:5432/postgres" . $.Release.Namespace }}
  db-username: '{secret-username}'
  db-password: '{secret-password}'

{{- end }}

{{- end }}
{{- end }}
{{- end }}
