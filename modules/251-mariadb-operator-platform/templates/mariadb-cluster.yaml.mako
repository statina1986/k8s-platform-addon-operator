<%! 
import json
import base64
%>

{{- if .Values.mariadbOperatorPlatform }}
{{- $root := . }}
{{- range keys .Values.mariadbOperatorPlatform.clusters  }}
{{- $dbCluster := get $.Values.mariadbOperatorPlatform.clusters . }}
{{- $dbClusterName := . }}

{{- if ne $dbCluster nil }}

{{- $cluster := deepCopy $dbCluster }}
{{- $addonoperator := "${ base64.b64encode(json.dumps(addon_operator).encode('utf-8')).decode('utf-8')}" | b64dec | fromJson }}
{{- $defaultTemplate := tpl $root.Values.mariadbOperatorPlatform.common.defaultClusterTemplate (dict "cluster" $dbCluster "root" $root "addonOperator" $addonoperator "clusterName" .) | fromYaml }}
{{- $cluster := mergeOverwrite ($defaultTemplate | deepCopy) ($root.Values.mariadbOperatorPlatform.common.defaultCluster | default (dict) | deepCopy) $cluster }}

{{- if $cluster.enabled }}
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: MariaDB
metadata:
  name: {{ $dbClusterName }}
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
  name: admin-role-{{ $dbClusterName }}
spec:
  db-name: {{ . }}
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT GRANT OPTION, SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER ON *.* TO '{{name}}'@'%%';" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readonly-role-{{ $dbClusterName }}
spec:
  db-name: {{ . }}
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT SELECT, SHOW DATABASES, SHOW VIEW ON *.* TO '{{name}}'@'%%';" }}

---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readwrite-role-{{ $dbClusterName }}
spec:
  db-name: {{ . }}
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
{{- end }}
{{- end }}
{{- end }}
