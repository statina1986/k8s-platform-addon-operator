<%! 
import json
import base64
%>
{{- if and .Values.qvantelGlue.dbs .Values.qvantelGlue.dbs.mariadb }}
{{- $addonOperator := "${ base64.b64encode(json.dumps(addon_operator).encode('utf-8')).decode('utf-8')}" | b64dec | fromJson }}
{{- $root := . }}
{{- range keys .Values.qvantelGlue.dbs.mariadb  }}
{{- $dbCluster := get $.Values.qvantelGlue.dbs.mariadb . }}
{{- $dbClusterName := . }}

{{- $cluster := mergeOverwrite ($root.Values.qvantelGlue.dbs.common.mariadb.defaultCluster | default (dict) | deepCopy) ($dbCluster.cluster | default (dict) | deepCopy) }}
{{- $defaultTemplate := tpl $root.Values.qvantelGlue.dbs.common.mariadb.defaultClusterTemplate (dict "cluster" $dbCluster.cluster "root" $root "addonOperator" $addonOperator "clusterName" .) | fromYaml }}
{{- $cluster := mergeOverwrite ($defaultTemplate | deepCopy) ($root.Values.qvantelGlue.dbs.common.mariadb.defaultCluster | default (dict) | deepCopy) $cluster }}
{{- $_ := set $dbCluster "cluster" $cluster}}

### MariaDB Cluster resource
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

### Additional service pointing to cluster "primary" entrypoint be used by applications
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

### Additional MaxScale deployment if enabled for the cluster
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


### Physical ScheduledBackup for cluster
{{- if and $cluster.spec $cluster.spec.backup (eq $cluster.spec.backup.type "physical") $cluster.spec.backup.scheduledBackup }}
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
# end physical backup block

{{- if and $cluster.spec $cluster.spec.backup (eq (default "logical" $cluster.spec.backup.type) "logical") $cluster.spec.backup.scheduledBackup }}
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: Backup
metadata:
  name: {{ $dbClusterName }}-logical-scheduled-backups
spec:
  mariaDbRef:
    name: {{ $dbClusterName }}
  serviceAccountName: platform
  maxRetention: {{ $cluster.spec.backup.retention | default "48h" }}
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
            storage: {{ $cluster.spec.backup.stagingStorage | default "5Gi" }}
        accessModes:
          - ReadWriteOnce
  compression: gzip
  schedule:
    cron: {{ $cluster.spec.backup.scheduledBackup | default "0 0 * * *" }}
    suspend: {{ $cluster.spec.backup.suspend | default "false" }}
    immediate: true
{{- end }}
# end logical backup block

{{- if eq $addonOperator.monitoringPlatformEnabled "true" }}
---
apiVersion: platform.qvantel.com/v1
kind: SqlInstaller
metadata:
  annotations:
    platform.qvantel.com/retry-count: "100"
  name: {{ $dbClusterName }}-init-monitoring
spec:
  type: mariadb  
  db-provision-sql:
    - "UPDATE performance_schema.setup_instruments SET ENABLED='YES', TIMED='YES' WHERE NAME REGEXP '^(statement/|wait/|stage/)';"
  db-username: 'root'
  db-password: "{mariadb-password}"
  db-url: {{ $dbClusterName }}-main.{{$.Release.Namespace}}.svc
  computed-values:
    - name: "mariadb-password"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-root', '{{ $.Release.Namespace }}', 'password')"

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $dbClusterName }}-sql-exporter-config
  labels:
    app.kubernetes.io/name: {{ $dbClusterName }}-sql-exporter
    app.kubernetes.io/part-of: mariadb
data:
  config.yml: |
    {{- tpl $defaultTemplate.defaultSqlExporter.config.content $root | nindent 4 }}

{{- $replicas := int (default 1 $cluster.spec.replicas) }}
{{- range $i, $_ := until $replicas }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ printf "%s-pod-%d" $dbClusterName $i }}
  labels:
    app.kubernetes.io/name: {{ $dbClusterName }}-sql-exporter
    app.kubernetes.io/part-of: mariadb
    mariadb.com/exporter-target: {{ printf "%s-%d" $dbClusterName $i }}
spec:
  clusterIP: None
  type: ClusterIP
  selector:
    app.kubernetes.io/name: mariadb
    app.kubernetes.io/instance: {{ $dbClusterName }}
    apps.kubernetes.io/pod-index: "{{ $i }}"
  ports:
    - name: mariadb
      port: 3306
      targetPort: 3306
      protocol: TCP
{{- end }}
# sqlexporter pods svc block

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ $dbClusterName }}-sql-exporter
  labels:
    app.kubernetes.io/name: {{ $dbClusterName }}-sql-exporter
    app.kubernetes.io/part-of: mariadb
spec:
  serviceName: {{ $dbClusterName }}-sql-exporter
  replicas: {{ $replicas }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ $dbClusterName }}-sql-exporter
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ $dbClusterName }}-sql-exporter
        app.kubernetes.io/part-of: mariadb
    spec:
      initContainers:
        - name: render-config
          image: python:3.12-alpine
          command:
            - /bin/sh
            - -ec
            - |
              python - <<'PY'
              import os
              import urllib.parse

              pw = os.environ.get('MYSQL_PASSWORD', '')
              ns = os.environ.get('POD_NAMESPACE', '')
              pod_name = os.environ.get('POD_NAME', '')
              cluster = os.environ.get('EXPORTER_CLUSTER_NAME', '')
              default_host = os.environ.get('EXPORTER_DEFAULT_HOST', '')
              cluster_domain = os.environ.get('CLUSTER_DOMAIN', 'cluster.local')
              port = os.environ.get('EXPORTER_TARGET_PORT', '') or '3306'

              ordinal = ''
              if pod_name:
                  suffix = pod_name.rsplit('-', 1)[-1]
                  if suffix.isdigit():
                      ordinal = suffix

              host = ''
              pod_id = ''
              if ordinal and cluster and ns:
                  svc_host = f"{cluster}-pod-{ordinal}.{ns}.svc"
                  host = f"{svc_host}.{cluster_domain}" if cluster_domain else svc_host
                  pod_id = f"{cluster}-{ordinal}"
              else:
                  fallback_host = default_host or (f"{cluster}-main.{ns}.svc" if cluster else '')
                  host = fallback_host or 'localhost'
                  pod_id = cluster or host or 'mariadb'

              quoted_pw = urllib.parse.quote(pw, safe='')
              dsn = f"mysql://root:{quoted_pw}@{host}:{port}/"

              with open('/config-template/config.yml', 'r', encoding='utf-8') as src:
                  content = src.read()

              content = content.replace('__DSN__', dsn)

              with open('/config/config.yml', 'w', encoding='utf-8') as dst:
                  dst.write(content)
              PY
          env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ $dbClusterName }}-root
                  key: password
            - name: EXPORTER_CLUSTER_NAME
              value: {{ $dbClusterName | quote }}
            - name: EXPORTER_DEFAULT_HOST
              value: {{ printf "%s-main.%s.svc" $dbClusterName $.Release.Namespace | quote }}
            - name: EXPORTER_TARGET_PORT
              value: "3306"
            - name: CLUSTER_DOMAIN
              value: {{ $root.Values.global.clusterDomain | default "cluster.local" | quote }}
          volumeMounts:
            - name: config-template
              mountPath: /config-template
            - name: config
              mountPath: /config
      containers:
        - name: sql-exporter
          image: docker.io/burningalchemist/sql_exporter:0.18
          imagePullPolicy: IfNotPresent
          args:
            - "--config.file=/config/config.yml"
            - "--web.listen-address=:{{ $defaultTemplate.defaultSqlExporter.service.port | default 9399 }}"
          ports:
            - name: http
              containerPort: {{ $defaultTemplate.defaultSqlExporter.service.port | default 9399 }}
          readinessProbe:
            httpGet:
              path: /metrics
              port: http
              scheme: HTTP
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 3
          volumeMounts:
            - name: config
              mountPath: /config
          resources: {}
      volumes:
        - name: config-template
          configMap:
            name: {{ $dbClusterName }}-sql-exporter-config
        - name: config
          emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: {{ $dbClusterName }}-sql-exporter
  labels:
    app.kubernetes.io/name: {{ $dbClusterName }}-sql-exporter
    app.kubernetes.io/part-of: mariadb
spec:
  clusterIP: None
  type: ClusterIP
  ports:
    - name: http
      port: {{ $defaultTemplate.defaultSqlExporter.service.port | default 9399 }}
      targetPort: http
  selector:
    app.kubernetes.io/name: {{ $dbClusterName }}-sql-exporter

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ $dbClusterName }}-sql-exporter
  labels:
    release: "{{ $root.Values.global.helmReleaseNamePrefix }}monitoring-platform"
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ $dbClusterName }}-sql-exporter
  endpoints:
    - port: http
      path: /metrics
      scheme: http
      metricRelabelings:
        - targetLabel: mariadb_cluster
          replacement: {{ $dbClusterName }}
{{- end }}
# end mariadb extended monitoring block

### Cluster level Vault Configuration, i.e. DB Connection and cluster scoped roles
{{- if $cluster.vaultConfiguration }}
#
## Vault DB Admin Role
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: admin-role-{{ $dbClusterName }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT GRANT OPTION, SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER ON *.* TO '{{name}}'@'%%';" }}

### Vault DB Readonly Role
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readonly-role-{{ $dbClusterName }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT SELECT, SHOW DATABASES, SHOW VIEW ON *.* TO '{{name}}'@'%%';" }}

### Vault DB ReadWrite Role
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readwrite-role-{{ $dbClusterName }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT SELECT, SHOW DATABASES, SHOW VIEW, INSERT, UPDATE, DELETE, EXECUTE ON *.* TO '{{name}}'@'%%';" }}

### Vault DB Connection
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

### If additional roles defined for cluster
{{- if $dbCluster.roles }}
{{- range keys $dbCluster.roles  }}
{{- $dbrole := get $dbCluster.roles . }}
{{- $dbRoleName := . }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbRoleName }}
spec:  
  creation-statements: {{ $dbrole.sql }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: {{ $dbRoleName }}
{{- end }}
{{- end }}
### End of additional Vault roles

{{- end }}
### End of Cluster level Vault configuration block

### Resources per Cluster database
{{- if $dbCluster.dbs }}
{{- range keys $dbCluster.dbs  }}
{{- $db := get $dbCluster.dbs . }}
{{- $dbName := . }}
{{- $dbNameUnderscored := ( . | replace "-" "_") }}

### SqlInstaller for database creation per Qvantel conventions
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
    - "CREATE DATABASE IF NOT EXISTS {{ $dbNameUnderscored }} CHARACTER SET utf8mb4 COLLATE uca1400_ai_ci;"
  {{ end }}  
  db-username: 'root'
  db-password: "{mariadb-password}"
  db-url: {{ $dbClusterName }}-main.{{$.Release.Namespace}}.svc
  computed-values:
    - name: "mariadb-password"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-root', '{{ $.Release.Namespace }}', 'password')"

### Vault roles per database
{{- if $dbCluster.cluster.vaultConfiguration }}

### Default Vault role for DB owner application per Qvantel conventions
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbClusterName }}-{{ $dbName }}-{{ $db.namespace | default $root.Values.global.appsNamespace }}
spec:
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REFERENCES, CREATE VIEW, CREATE ROUTINE, SHOW VIEW ON %s.* TO '{{name}}'@'%%';" $dbNameUnderscored }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: {{ $db.namespace | default $root.Values.global.appsNamespace }}-{{ $dbName }}-{{ $dbClusterName }}

### Vault roles for additional owners roles, if defined
{{- if $db.owners }}
{{- range keys $db.owners  }}
{{- $dbrole := get $db.owners . }}
{{- $dbRoleName := . }}
{{- $objName := printf "%s-%s-%s" $dbClusterName $dbName $dbRoleName | replace "_" "-" }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbrole }}
spec:
  creation-statements: >-
    {{ printf "CREATE USER '{{name}}'@'%%' IDENTIFIED BY '{{password}}'; GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REFERENCES, CREATE VIEW, CREATE ROUTINE, SHOW VIEW ON %s.* TO '{{name}}'@'%%';" $dbNameUnderscored }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: {{ $dbRoleName }}
{{- end }}
{{- end }}

{{- end }}
### End of Database level Vault configuration block


{{- end }}
{{- end }}
### End of per-database resources section

{{- end }}
{{- end }}
