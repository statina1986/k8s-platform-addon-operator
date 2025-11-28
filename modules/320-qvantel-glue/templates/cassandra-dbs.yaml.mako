<%! 
import json
import base64
%>
{{- if and .Values.qvantelGlue.dbs .Values.qvantelGlue.dbs.cassandra }}
{{- $addonOperator := "${ base64.b64encode(json.dumps(addon_operator).encode('utf-8')).decode('utf-8')}" | b64dec | fromJson }}
{{- $root := . }}
{{- range keys .Values.qvantelGlue.dbs.cassandra  }}
{{- $dbCluster := get $.Values.qvantelGlue.dbs.cassandra . }}
{{- $dbClusterName := . }}

{{- $cluster := mergeOverwrite ($root.Values.qvantelGlue.dbs.common.cassandra.defaultCluster | default (dict) | deepCopy) ($dbCluster.cluster | default (dict) | deepCopy) }}
{{- $defaultTemplate := tpl $root.Values.qvantelGlue.dbs.common.cassandra.defaultClusterTemplate (dict "cluster" $cluster "root" $root "addonOperator" $addonOperator "clusterName" .) | fromYaml }}
{{- $cluster := mergeOverwrite ($defaultTemplate | deepCopy) ($root.Values.qvantelGlue.dbs.common.cassandra.defaultCluster | default (dict) | deepCopy) $cluster }}

# Deep merge .spec and .spec.cassandra
{{- $specDefault := ($defaultTemplate.spec | default dict) }}
{{- $specUser := ($cluster.spec | default dict) }}
{{- $spec := mergeOverwrite ((deepCopy $specDefault)) ((deepCopy $specUser)) }}

{{- $cassDefault := ($specDefault.cassandra | default dict) }}
{{- $cassUser := ($specUser.cassandra | default dict) }}
{{- $cassandra := mergeOverwrite ((deepCopy $cassDefault)) ((deepCopy $cassUser)) }}

# Deep merge datacenters by index
{{- $dcsDefault := ($cassDefault.datacenters | default (list)) }}
{{- $dcsUser := ($cassUser.datacenters | default (list)) }}
{{- $dcs := list }}

# For each default DC, merge with user defined DC at same index (if any)
{{- range $i, $dcDef := $dcsDefault }}
  {{- $dcUsr := (index $dcsUser $i) | default dict }}
  {{- $dcMerged := mergeOverwrite ((deepCopy $dcDef)) ((deepCopy $dcUsr)) }}
  {{- $dcs = append $dcs $dcMerged }}
{{- end }}

# If more DCs than defaults, append them as-is
{{- if gt (len $dcsUser) (len $dcsDefault) }}
  {{- range $j, $extra := (slice $dcsUser (len $dcsDefault)) }}
    {{- $dcs = append $dcs $extra }}
  {{- end }}
{{- end }}

# Set merged datacenters
{{- $_ := set $cassandra "datacenters" $dcs }}

# Ensure cluster-level storageConfig exists (so K8ssandra Admission webhook is happy even if DCs don’t define it)
{{- if not (hasKey $cassandra "storageConfig") }}
  {{- $_ := set $cassandra "storageConfig" (dict "cassandraDataVolumeClaimSpec" (dict
      "accessModes" (list "ReadWriteOnce")
      "resources" (dict "requests" (dict "storage" (ternary "10Gi" "20Gi" (eq $.root.Values.global.configurationProfile "dev")))))) }}
{{- end }}

# Finalize .spec and assign to cluster
{{- $_ := set $spec "cassandra" $cassandra }}
{{- $_ := set $cluster "spec" $spec }}
{{- $_ := set $dbCluster "cluster" $cluster }}

### Cassandra cluster resource
---
apiVersion: k8ssandra.io/v1alpha1
kind: K8ssandraCluster
metadata:
  name: {{ $dbClusterName }}
spec:
  {{- toYaml $cluster.spec | nindent 2 }}

### Reaper service
---
apiVersion: v1
kind: Service
metadata:
  name: reaper
spec:
  ports:
    - name: app
      port: 8080
      protocol: TCP
      targetPort: app
    - name: admin
      port: 8081
      protocol: TCP
      targetPort: admin
  selector:
    app.kubernetes.io/component: reaper
    app.kubernetes.io/managed-by: k8ssandra-operator
    app.kubernetes.io/name: k8ssandra-operator
    app.kubernetes.io/part-of: k8ssandra
  sessionAffinity: None
  type: ClusterIP

### Job that patches Reaper DC availability
---
{{- $dataCenter := (index $dcs 0)}}
{{- if and $cluster.spec.reaper (hasKey $cluster.spec.reaper "datacenterAvailability") }}
{{- $availability := (index $cluster.spec.reaper.datacenterAvailability) }}
apiVersion: batch/v1
kind: Job
metadata:
  name: patch-{{ $dbClusterName }}-reaper-dc-availability
  annotations:
    "helm.sh/hook": post-install,post-upgrade
spec:
  ttlSecondsAfterFinished: 30  # Job will be deleted 30s after completion
  backoffLimit: 3  # Retry limit
  template:
    spec:
      serviceAccountName: platform
      containers:
      - name: patch-reaper
        image: {{ $.Values.global.containerRegistryBase | default "platform.artifactory.qvantel.net" }}/platform/platform-k8s-tools-minimal:1.3.2_202508131123_master_e140ddde
        command:
        - /bin/sh
        - -c
        - |
          echo "Waiting for Reaper CR to be created..."
          until kubectl get reaper {{ $dbClusterName }}-{{ $dataCenter.metadata.name }}-reaper -n {{ $.Release.Namespace }}; do sleep 5; done
          echo "Patching Reaper..."
          kubectl patch reaper {{ $dbClusterName }}-{{ $dataCenter.metadata.name }}-reaper -n {{ $.Release.Namespace }} --type merge -p '{"spec":{"datacenterAvailability":"{{$availability}}"}}'
      restartPolicy: OnFailure
{{- end }}

### Cassandra cluster snapshot cleaner
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $dbClusterName }}-snapshot-cleaner
spec:
  schedule: {{ $cluster.snaphotCleanerSchedule }}
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 30  # Job will be deleted 30s after completion
      backoffLimit: 3  # Retry limit
      template:
        spec:
          serviceAccountName: platform
          containers:
            - name: snapshot-cleaner
              image: {{ $.Values.global.containerRegistryBase | default "platform.artifactory.qvantel.net" }}/platform/platform-k8s-tools-minimal:1.3.2_202508131123_master_e140ddde
              command:
              - /bin/sh
              - -c
              - |
                # Construct the username
                USER="{{ $dbClusterName }}-superuser"

                # Extract the password from the secret
                PASSWORD=$(kubectl get secret "$USER" -n {{ $.Release.Namespace }} -o jsonpath="{.data.password}" | base64 --decode)

                # Clear snapshots
                for pod in $(kubectl get pods -n {{ $.Release.Namespace }} -l app.kubernetes.io/name=cassandra -l cassandra.datastax.com/cluster={{ $dbClusterName }} -o jsonpath='{.items[*].metadata.name}'); do
                  kubectl exec -it -n {{ $.Release.Namespace }} $pod -c cassandra -- nodetool -u $USER -pw $PASSWORD clearsnapshot --all;
                done
          restartPolicy: OnFailure # Retry the job if it fails
---
### MedusaBackupSchedule
{{- if $cluster.spec.medusa }}
apiVersion: medusa.k8ssandra.io/v1alpha1
kind: MedusaBackupSchedule
metadata:
  name: {{ $dbClusterName }}-medusa-backup-schedule
spec:
  backupSpec:
    backupType: {{ $cluster.medusaBackupType }}
    cassandraDatacenter: {{ $dataCenter.metadata.name }}
  cronSchedule: {{ $cluster.medusaBackupSchedule }}
  operationType: backup
{{- end }}

### Main cluster services
---
{{- if $cluster.mainCassandraCluster }}
{{- $main := $cluster.mainCassandraCluster }}

apiVersion: v1
kind: Service
metadata:
  annotations:
    consul.hashicorp.com/service-port: native
    platform.qvantel.com/consul-service-port: "9042"
  labels:
    app: main-cassandra-service
  name: main-cassandra-service
spec:
  ports:
    - name: native
      port: 9042
      protocol: TCP
      targetPort: 9042
    - name: tls-native
      port: 9142
      protocol: TCP
      targetPort: 9142
    - name: mgmt-api
      port: 8080
      protocol: TCP
      targetPort: 8080
    - name: prometheus
      port: 9103
      protocol: TCP
      targetPort: 9103
    - name: metrics
      port: 9000
      protocol: TCP
      targetPort: 9000
    - name: thrift
      port: 9160
      protocol: TCP
      targetPort: 9160
  selector:
    cassandra.datastax.com/cluster: {{ $dbClusterName }}
    cassandra.datastax.com/datacenter: {{ $dataCenter.metadata.name  }}
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    consul.hashicorp.com/service-port: native
    platform.qvantel.com/consul-service-port: "9042"
  labels:
    app: main-cassandra-service-0-headless
  name: main-cassandra-service-0-headless
spec:
  ports:
  - name: native
    port: 9042
    protocol: TCP
    targetPort: 9042
  - name: tls-native
    port: 9142
    protocol: TCP
    targetPort: 9142
  selector:
    cassandra.datastax.com/cluster: {{ $dbClusterName }}
    cassandra.datastax.com/datacenter: {{ $dataCenter.metadata.name }}
{{- if $dataCenter.racks }}
    statefulset.kubernetes.io/pod-name: {{ lower $dbClusterName }}-{{ $dataCenter.metadata.name }}-{{ (first $dataCenter.racks).name }}-sts-0
{{- else }}    
    statefulset.kubernetes.io/pod-name: {{ lower $dbClusterName }}-{{ $dataCenter.metadata.name  }}-default-sts-0
{{- end }}
{{- end }}
---
### Cluster level Vault Configuration, i.e. DB Connection and cluster scoped roles
{{- if $cluster.vaultConfiguration }}
## DB connection
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbConnection
metadata:
  name: {{ $dbClusterName }}
spec:
  connection-name: {{ $dbClusterName }}
  plugin-name: cassandra-database-plugin
  allowed-roles: '*'  
  additional-params:
    hosts: {{ $dbClusterName }}-{{ $dataCenter.metadata.name }}-service.{{ $.Release.Namespace }}.svc
    protocol_version: "4"
    username_template: >-
      {{ printf "{{ printf \"v_%%s_%%s_%%s_%%s\" (.DisplayName | truncate 15) (.RoleName | truncate 15) (random 20) (unix_time) | truncate 100 | replace \"-\" \"_\" |replace \".\" \"_\" | lowercase }}" }}
  computed-values:
  - expression: k8s_get_secret_value('{{ $dbClusterName }}-superuser','{{ $.Release.Namespace }}','username')
    name: secret-username
  - expression: k8s_get_secret_value('{{ $dbClusterName }}-superuser','{{ $.Release.Namespace }}','password')
    name: secret-password
  db-username: '{secret-username}'
  db-password: '{secret-password}'

## Admin role
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: admin-role-{{ $dbClusterName }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE USER '{{username}}' WITH PASSWORD '{{password}}' NOSUPERUSER; GRANT ALL PERMISSIONS ON ALL KEYSPACES TO {{username}};" }}

## Readonly role
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readonly-role-{{ $dbClusterName }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE ROLE {{username}} WITH PASSWORD = '{{password}}' AND LOGIN = true AND SUPERUSER = false; GRANT SELECT ON ALL KEYSPACES TO {{username}};" }}

## Readwrite role 
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: readwrite-role-{{ $dbClusterName }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE ROLE {{username}} WITH PASSWORD = '{{password}}' AND LOGIN = true AND SUPERUSER = false; GRANT SELECT ON ALL KEYSPACES TO {{username}}; GRANT MODIFY ON ALL KEYSPACES TO {{username}};" }}
{{- end }}
### End of Cluster level Vault configuration block

## Additional CQL installer resources per Cluster database
{{- if $dbCluster.dbs }}
{{- range keys $dbCluster.dbs  }}
{{- $db := get $dbCluster.dbs . }}
{{- $db_name := . }}
{{- $db_name_underscore := ( . | replace "-" "_") }}
{{- $db_rf := ( $db.replicationFactors | default "{'class':'NetworkTopologyStrategy', 'dc1': 1}") }}
---
apiVersion: platform.qvantel.com/v1
kind: CqlInstaller
metadata:
  annotations:
    platform.qvantel.com/retry-count: "100"
  name: {{ $dbClusterName }}-{{ $db_name }}-installer
spec:  
  {{- if and $db.cql $db.cql.provision }}
  db-provision-cql:
    {{- tpl (toYaml $db.cql.provision) $root | nindent 2 }}
  {{- else }}
  db-provision-cql:
    - "CREATE KEYSPACE IF NOT EXISTS {{ $db_name_underscore }} WITH replication = {{ $db_rf }} AND durable_writes = true;"
    - "ALTER KEYSPACE {{ $db_name_underscore }} WITH replication = {{ $db_rf }} AND durable_writes = true;"
  {{ end }}
  {{- if and $db.cql $db.cql.additional }}
  additional-cql:
    {{- tpl (toYaml $db.cql.additional) $root | nindent 2 }}
  {{ end }}
  db-username: "{cass-user}"
  db-password: "{cass-password}"
  db-url: {{ $dbClusterName }}-{{ $dataCenter.metadata.name }}-service.{{ $.Release.Namespace }}.svc
  computed-values:
    - name: "cass-password"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'password')"
    - name: "cass-user"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'username')"

## Additional global CQL installer resources
{{- if $dbCluster.cqls }}
{{- range keys $dbCluster.cqls  }}
{{- $cql := get $dbCluster.cqls . }}
---
apiVersion: platform.qvantel.com/v1
kind: CqlInstaller
metadata:
  annotations:
    platform.qvantel.com/retry-count: "100"
  name: {{ $dbClusterName }}-{{ $db_name }}-installer
spec:    
  db-provision-cql:
    {{- tpl (toYaml $cql.cql) $root | nindent 2 }}   
  db-username: "{cass-user}"
  db-password: "{cass-password}"
  db-url: {{ $dbClusterName }}-{{ $dataCenter.metadata.name }}-service.{{ $.Release.Namespace }}.svc
  computed-values:
    - name: "cass-password"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'password')"
    - name: "cass-user"
      expression: "k8s_get_secret_value('{{ $dbClusterName }}-superuser', '{{ $.Release.Namespace }}', 'username')"
{{- end }}
{{- end }}

### If additional roles defined for cluster
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
  creation-statements: {{ $dbRole.cql }}
  db-name: {{ $dbClusterName }}
  default-ttl: "0"
  max-ttl: "0"
  role-name: {{ $dbRoleName }}
{{- end }}
{{- else }}
---
apiVersion: platform-vault.qvantel.com/v1
kind: DbRole
metadata:
  name: {{ $dbClusterName }}-{{ $db_name }}-{{ $db.namespace | default $root.Values.global.appsNamespace }}
spec:
  db-name: {{ $dbClusterName }}
  creation-statements: >-
    {{ printf "CREATE USER '{{username}}' WITH PASSWORD '{{password}}' NOSUPERUSER; GRANT ALL PERMISSIONS ON KEYSPACE %s TO {{username}};" $db_name_underscore }}
  role-name: {{ $db.namespace | default $root.Values.global.appsNamespace }}-{{ $db_name }}-{{ $dbClusterName }}
{{- end }}


{{- end }}
{{- end }}


{{- end }}
{{- end }}
