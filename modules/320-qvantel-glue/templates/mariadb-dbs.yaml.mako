<%! 
import json
import base64
%>
{{- if .Values.qvantelGlue.dbs.mariadb }}
{{- $root := . }}
{{- range keys .Values.qvantelGlue.dbs.mariadb  }}
{{- $dbCluster := get $.Values.qvantelGlue.dbs.mariadb . }}
{{- $dbClusterName := . }}


{{- if ne $dbCluster.cluster nil }}

{{- $cluster := $dbCluster.cluster | default (dict) | deepCopy }}
{{- $addonoperator := "${ base64.b64encode(json.dumps(addon_operator).encode('utf-8')).decode('utf-8')}" | b64dec | fromJson }}
{{- $defaultTemplate := tpl $root.Values.qvantelGlue.dbs.common.mariadb.defaultClusterTemplate (dict "cluster" $dbCluster.cluster "root" $root "addonOperator" $addonoperator "clusterName" .) | fromYaml }}
{{- $cluster := mergeOverwrite ($defaultTemplate | deepCopy) ($root.Values.qvantelGlue.dbs.common.mariadb.defaultCluster | default (dict) | deepCopy) $cluster }}
{{- $_ := set $dbCluster "cluster" $cluster}}

---
apiVersion: k8s.mariadb.com/v1alpha1
kind: MariaDB
metadata:
  name: {{ . }}
  {{- with $cluster.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    app.kubernetes.io/name: {{ $dbClusterName }}
    app.kubernetes.io/instance: {{ $dbClusterName }}
    app.kubernetes.io/part-of: mariadb
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
    mariadb.com/cluster: {{ $dbClusterName }}
  name: {{ $dbClusterName }}-main
spec:
  internalTrafficPolicy: Cluster
  ports:
  - name: mariadb
    port: 3306
    protocol: TCP
    targetPort: 3306
  selector:
    {{- if and (hasKey $cluster.spec "maxScale") $cluster.spec.maxScale.enabled }}
    app.kubernetes.io/instance: {{ $dbClusterName }}-maxscale
    app.kubernetes.io/name: maxscale
    {{- else }}
    app.kubernetes.io/instance: {{ $dbClusterName }}
    app.kubernetes.io/name: mariadb 
    {{- end }}    
  sessionAffinity: None
  type: ClusterIP


{{- if $cluster.vaultConfiguration }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: admin-role-{{ . }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT GRANT OPTION, SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER ON *.* TO '{{name}}'@'%%';" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readonly-role-{{ . }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT SELECT, SHOW DATABASES, SHOW VIEW ON *.* TO '{{name}}'@'%%';" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readwrite-role-{{ . }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT SELECT, SHOW DATABASES, SHOW VIEW, INSERT, UPDATE, DELETE, EXECUTE ON *.* TO '{{name}}'@'%%';" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbConnection
metadata:
  annotations:
    platform.qvantel.com/retry-count: "100"
  name: {{ $dbClusterName }}
spec:
  connection-name: {{ $dbClusterName }}
  plugin-name: mysql-database-plugin
  allowed-roles: '*'
  computed-values:
  - expression: k8s_get_secret_value('{{ $dbClusterName }}-root','{{ $.Release.Namespace }}','password')
    name: secret-password
  db-url: >-
    {{ printf "{{username}}:{{password}}@tcp(%s-main.%s.svc:3306)/" $dbClusterName $.Release.Namespace }}
  db-username: 'root'
  db-password: '{secret-password}'
{{- end }}

{{- if and (hasKey $cluster.spec "maxScale") $cluster.spec.maxScale.enabled }}
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: MaxScale
metadata:
  name: {{ $dbClusterName }}-maxscale
spec:
  replicas: {{ $cluster.spec.maxScale.replicas | default "1" }}
  mariaDbRef:
    name: {{ $dbClusterName }}
  services:
    - name: rw-router
      router: readwritesplit
      params:
        enable_root_user: "true"
      listener:
        port: 3306
        protocol: MariaDBProtocol
{{- end }}

{{- if and $cluster.spec (and $cluster.spec.backup $cluster.spec.backup.scheduledBackup) }}
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: PhysicalBackup
metadata:
  name: {{ $dbClusterName }}-scheduled-backups
spec:
  mariaDbRef:
    name: {{ $dbClusterName }}
  serviceAccountName: platform
  maxRetention: {{ $cluster.spec.backup.retention | default "48h" }}
  timeout: {{ $cluster.spec.backup.timeout | default "2h" }}
  storage:
    s3:
      bucket: {{ $cluster.spec.backup.bucket }}
      prefix: {{ $dbClusterName }}
      endpoint: {{ $cluster.spec.backup.endpoint }}
      region: {{ $cluster.spec.backup.region }}
      {{- if $cluster.spec.backup.secretName }}
      accessKeyIdSecretKeyRef:
        name: {{ $cluster.spec.backup.secretName }}
        key: {{ $cluster.spec.backup.secretUserKey }}
      secretAccessKeySecretKeyRef:
        name: {{ $cluster.spec.backup.secretName }}
        key: {{ $cluster.spec.backup.secretKey }}
      {{- end }}
      tls:
        enabled: false
  stagingStorage:
    persistentVolumeClaim:
      resources:
        requests:
          storage: {{ $cluster.spec.backup.stagingStorage | default "10Gi" }}
      accessModes:
        - ReadWriteOnce
  compression: gzip
  schedule:
    cron: {{ $cluster.spec.backup.scheduledBackup | default "0 0 * * *" }}
    suspend: {{ $cluster.spec.backup.suspend | default "false" }}
    immediate: true
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
  type: mariadb
  {{- if and $db.sql $db.sql.provision }}
  db-provision-sql:
    {{- tpl (toYaml $db.sql.provision) $root | nindent 2 }}
  {{- else }}
  db-provision-sql:
    - "CREATE DATABASE IF NOT EXISTS {{ $dbNameUnderscored }} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  {{ end }}  
  db-username: 'root'
  db-password: "{mariadb-password}"
  db-url: {{ $dbClusterName }}-main.{{$.Release.Namespace}}.svc
  computed-values:
    - name: "mariadb-password"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-root', '{{ $.Release.Namespace }}', 'password')"

{{- if $db.roles }}
{{- range keys $db.roles  }}
{{- $dbrole := get $db.roles . }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbrole }}
spec:
  creation-statements: {{ $dbrole.sql }} 
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: {{ $dbrole }}

{{- end }}
{{- else }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: mariadb-{{ . }}
spec:
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REFERENCES, CREATE VIEW, CREATE ROUTINE, SHOW VIEW ON %s.* TO '{{name}}'@'%%';" $dbNameUnderscored }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: mariadb_{{ . }}

{{- end }}


{{- end }}
{{- end }}


{{- if $dbCluster.roles }}
{{- range keys $dbCluster.roles  }}
{{- $dbrole := get $dbCluster.roles . }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbrole }}
spec:  
  creation-statements: {{ $dbrole.sql }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: {{ $dbrole }}

{{- end }}
{{- end }}


{{- end }}
{{- end }}
