<%! 
import json
import base64
%>
{{- if .Values.qvantelGlue.dbs.postgres }}
{{- $root := . }}
{{- range keys .Values.qvantelGlue.dbs.postgres  }}
{{- $dbCluster := get $.Values.qvantelGlue.dbs.postgres . }}
{{- $dbClusterName := . }}

{{- if ne $dbCluster.cluster nil }}

{{- $cluster := $dbCluster.cluster | default (dict) | deepCopy }}
{{- $addonoperator := "${ base64.b64encode(json.dumps(addon_operator).encode('utf-8')).decode('utf-8')}" | b64dec | fromJson }}
{{- $defaultTemplate := tpl $root.Values.qvantelGlue.dbs.common.postgres.defaultClusterTemplate (dict "cluster" $dbCluster.cluster "root" $root "addonOperator" $addonoperator) | fromYaml }}
{{- $cluster := mergeOverwrite ($defaultTemplate | deepCopy) ($root.Values.qvantelGlue.dbs.common.postgres.defaultCluster | default (dict) | deepCopy) $cluster }}
{{- $_ := set $dbCluster "cluster" $cluster}}

---
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: {{ $dbClusterName }}
  {{- with $dbCluster.cluster.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    app.kubernetes.io/name: {{ $dbClusterName }}
    app.kubernetes.io/instance: {{ $dbClusterName }}
    app.kubernetes.io/part-of: cloudnative-pg
    {{- with $dbCluster.cluster.additionalLabels }}
      {{ toYaml . | nindent 4 }}
    {{- end }}
spec:  
  {{- toYaml $dbCluster.cluster.spec | nindent 2 }}

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
      backoffLimit: 3
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
                    name: {{ $dbClusterName }}-superuser
              - name: POSTGRES_PASSWORD
                valueFrom:
                  secretKeyRef:
                    key: password
                    name: {{ $dbClusterName }}-superuser
              - name: POSTGRES_SERVICE
                value: "{{ $dbClusterName }}"
            command:
            - /bin/sh
            - -c
            - |
              date; echo 'Executing postgresql stats cleanup.'
              PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h $POSTGRES_SERVICE -c \
                "SELECT pg_wait_sampling_reset_profile(); SELECT pg_stat_statements_reset();"\
              && echo 'Postgresql stats cleanup completed.'
          restartPolicy: OnFailure          
  schedule: "@midnight"

{{- if $root.Values.qvantelGlue.monitoringPlatformEnabled }}
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


{{- if and $dbCluster.cluster.spec.backup $dbCluster.cluster.scheduledBackup }}
---
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: {{ $dbClusterName }}-scheduled-backups
spec:
  schedule: {{ $dbCluster.cluster.scheduledBackup }}
  backupOwnerReference: self
  cluster:
    name: {{ $dbClusterName }}
  immediate: true
  target: {{ $dbCluster.cluster.spec.backup.target | default "prefer-standby" }}
{{- end }}


{{- if $dbCluster.cluster.vaultConfiguration }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: admin-role-{{ $dbClusterName }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE USER \"{{name}}\" SUPERUSER PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readonly-role-{{ $dbClusterName }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT pg_read_all_data TO \"{{name}}\"" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readwrite-role-{{ $dbClusterName }}
spec:
  db-name: {{ $dbClusterName }}
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

{{- if $dbCluster.roles }}
{{- range keys $dbCluster.roles  }}
{{- $dbRole := get $dbCluster.roles . }}
{{- $dbRoleName := . }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbRoleName }}
spec:
  creation-statements: {{ $dbRole.sql }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: {{ $dbRoleName }}

{{- end }}
{{- end }}

{{- end }}

{{- end }}


{{- if $dbCluster.dbs }}
{{- range keys $dbCluster.dbs  }}
{{- $db := get $dbCluster.dbs . }}
{{- $dbName := . }}
{{- $dbNameUnderscored := ( . | replace "-" "_") }}

---
apiVersion: platform.qvantel.com/v1
kind: SqlInstaller
metadata:
  annotations:
    platform.qvantel.com/retry-count: "100"
  name: {{ $dbClusterName }}-{{ $dbName }}-installer
spec:
  type: postgresql
  {{- if and $db.sql $db.sql.provision }}
  db-provision-sql:
    {{- tpl (toYaml $db.sql.provision) $root | nindent 2 }}
  {{- else }}
  db-provision-sql:
    - "CREATE ROLE db_{{ $dbNameUnderscored }} NOLOGIN"    
    - "GRANT db_{{ $dbNameUnderscored }} TO CURRENT_USER"
    - "CREATE DATABASE {{ $dbNameUnderscored }} WITH OWNER db_{{ $dbNameUnderscored }}"  
  {{ end }}  
  db-username: postgres
  db-password: "{postgres-password}"
  transaction: false
  db-url: "postgresql://{postgres-user}:{postgres-password}@{{ $dbClusterName }}-rw.{{ $.Release.Namespace }}.svc:5432/postgres"
  computed-values:
    - name: "postgres-password"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'password')"
    - name: "postgres-user"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'username')"

---
apiVersion: platform.qvantel.com/v1
kind: SqlInstaller
metadata:
  annotations:
    platform.qvantel.com/retry-count: "100"
  name: {{ $dbClusterName }}-{{ $dbName }}-user
spec:
  type: postgresql
  db-provision-sql:
    - "CREATE ROLE db_{{ $dbNameUnderscored }}_user WITH LOGIN PASSWORD '{user-password}'"
    - "GRANT db_{{ $dbNameUnderscored }} TO db_{{ $dbNameUnderscored }}_user"
    - "ALTER ROLE db_{{ $dbNameUnderscored }}_user SET role db_{{ $dbNameUnderscored }}"    
  db-username: postgres
  db-password: "{postgres-password}"
  db-url: "postgresql://{postgres-user}:{postgres-password}@{{ $dbClusterName }}-rw.{{ $.Release.Namespace }}.svc:5432/postgres"
  computed-values:
    - name: "postgres-password"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'password')"
    - name: "postgres-user"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'username')"
    - name: "user-username"
      expression: "'db_{{ $dbNameUnderscored }}_user'"
    - name: "user-password"
      expression: "get_random_string(8)"
  post-actions:
    - name: "store username in secrets"
      expression: "k8s_store_secret_value('{{ $dbClusterName }}-{{ $dbName }}-secret', '{{ $.Values.global.appsNamespace }}', 'username', '{user-username}')"
    - name: "store password in secrets"
      expression: "k8s_store_secret_value('{{ $dbClusterName }}-{{ $dbName }}-secret', '{{ $.Values.global.appsNamespace }}', 'password', '{user-password}')"

{{- if $dbCluster.cluster.vaultConfiguration }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbClusterName }}-{{ $dbName }}-legacy-owner
spec:
  creation-statements: >-
    {{ printf "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';  GRANT db_%s TO \"{{name}}\"; ALTER ROLE \"{{name}}\" SET role db_%s;" $dbNameUnderscored $dbNameUnderscored }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: postgresql_{{ $dbName }}


{{- if $db.owners }}
{{- range keys $db.owners  }}
{{- $dbRole := get $db.owners . }}
{{- $dbRoleName := . }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbClusterName }}-{{ $dbName }}-{{ $dbRoleName }}
spec:
  creation-statements: >-
    {{ printf "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';  GRANT db_%s TO \"{{name}}\"; ALTER ROLE \"{{name}}\" SET role db_%s;" $dbNameUnderscored $dbNameUnderscored }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: {{ $dbRoleName }}

{{- end }}
{{- end }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbClusterName }}-{{ $dbName }}-{{ $root.Values.global.appsNamespace }}
spec:
  creation-statements: >-
    {{ printf "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';  GRANT db_%s TO \"{{name}}\"; ALTER ROLE \"{{name}}\" SET role db_%s;" $dbNameUnderscored $dbNameUnderscored }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: {{ $root.Values.global.appsNamespace }}-{{ $dbName }}-{{ $dbClusterName }}
{{- end }}

{{- if and $db.extensions $db.extensions.timescaledb }}
---
apiVersion: platform.qvantel.com/v1
kind: SqlInstaller
metadata:
  annotations:
    platform.qvantel.com/retry-count: "100"
  name: {{ $dbClusterName }}-{{ $dbName }}-tsdb
spec:
  type: postgresql
  db-provision-sql:
    - "CREATE EXTENSION IF NOT EXISTS timescaledb"
  db-username: postgres
  db-password: "{postgres-password}"
  db-url: "postgresql://{postgres-user}:{postgres-password}@{{ $dbClusterName }}-rw.{{ $.Release.Namespace }}.svc:5432/{{ $dbName }}"
  transaction: false
  computed-values:
    - name: "postgres-password"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'password')"
    - name: "postgres-user"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'username')"
{{ end }}

{{- end }}
{{- end }}


{{- end }}
{{- end }}
