

# qvantel-glue

`qvantel-glue` module provides abstractions and automations to support Qvantel workloads deployments and operations.
Those are opiniated templates which utilize Qvantel specific conventions.

Depends on modules:
- This is module is collection of thin wrappers on top existing functionality and resources.

Provides:
- SqlInstaller CRD
- Database deployments configuration
  - PostgreSQL (via CNPG)
  - MariaDB (via MariaDB-operator)
  - Cassandra (via k8ssandra)

## Values

<h3> Main Values</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
	<tr>
		<td style="width: 300px;">qvantelGlue.cqlinstallersCrdSync.enabled</td>
		<td>bool</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
		<td><div>

Enables SqlInstaller CRDs reconciliation

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.cqlinstallersCrdSync.namespaceSelector</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - platform</code></pre>
</td>
		<td><div>

Selector for namespaces from which sync SqlInstaller resources. Default is `platform` namespace.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.cqlinstallersCrdSync.schedule</td>
		<td>string</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>'*/5 * * * *'</code></pre>
</td>
		<td><div>

Schedule for periodic reconciliation. Default is "*/5 * * * *" - so every 5 minutes.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>see child items docs</code></pre>
</td>
		<td><div>

Databases deployment configuration.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.cassandra</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td><div>

Cassandra databases configuration. This is a map where each key corresponds to the K8ssandra cluster  and associated configuration like keyspaces and roles. For Example, see `example-cassandra` definition in Examples-Cassandra section below.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.common</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>see child items docs</code></pre>
</td>
		<td><div>

Common configurations to be used across databases

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.common.mariadb</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>see child items docs</code></pre>
</td>
		<td><div>

Common configurations for MariaDB databases

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.common.mariadb.defaultCluster</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td><div>

Default values for MariaDB clusters. See `example-mariadb.cluster` for reference. With this field you can configure common values for all MariaDB clusters, e.g. backup location and schedule.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.common.mariadb.defaultClusterTemplate</td>
		<td>tpl/string</td>
		<td>
<pre style="max-width:500px; overflow-x:auto; white-space: pre;" lang="tpl"><code>qvantelGlue.dbs.common.mariadb.defaultClusterTemplate: |
  {{- if eq $.addonOperator.vaultPlatformEnabled "true" }}
  vaultConfiguration: true
  {{- end }}
  spec:
    {{- if $.root.Values.global.platformMasters }}
    nodeSelector:
      {{ $.root.Values.global.platformMastersKey }}: {{ $.root.Values.global.platformMastersValue }}
    {{- end }}
    storage:
      size: 10Gi
    {{- if eq $.root.Values.global.configurationProfile "dev" }}
    replicas: 1
    {{- else }}
    replicas: 3
    galera:
      enabled: true
      config:
        reuseStorageVolume: true
      providerOptions:
        gcache.size: 128M
    maxScale:
      enabled: true
      replicas: 2
    {{- end }}
    {{- if  eq $.addonOperator.monitoringPlatformEnabled "true"}}
    metrics:
      enabled: true
      serviceMonitor:
        prometheusRelease: "{{ $.root.Values.global.helmReleaseNamePrefix }}monitoring-platform"
    {{- end }}
    affinity:
      antiAffinityEnabled: true 
    tolerations:
      - key: "k8s.mariadb.com/ha"
        operator: "Exists"
        effect: "NoSchedule"
      - key: "{{ $.root.Values.global.platformMastersKey }}"
        value: "{{ $.root.Values.global.platformMastersValue }}"
        operator: "Equal"
        effect: "NoSchedule"
    podDisruptionBudget:
      maxUnavailable: 33%
    updateStrategy:
      type: RollingUpdate
    myCnf: |
      [mariadb]
      bind-address=*
      default_storage_engine=InnoDB
      binlog_format=row
      innodb_autoinc_lock_mode=2
      max_allowed_packet=256M
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        memory: 1Gi 
       
 
</code></pre>
</td>
		<td><div>

Default template for MariaDB clusters. See `example-mariadb.cluster` for reference. This is templated field which is rendered for each cluster from `qvantelGlue.dbs.mariadb`. With this field you can override default cluster template for complex cases and utilize helm templating in it. Scope for the template contains fields: 
 * addonOperator: content from Addon Operator configmap. You can check if some modules, e.f. monitoring-platform are enabled.
 * root: root context of 'qvantel-glue' module, containing all Values for the module.
 * cluster: content of 'cluster' field for rendered cluster.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.common.postgres</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>see child items docs</code></pre>
</td>
		<td><div>

Common configurations for PostgreSQL databases

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.common.postgres.defaultCluster</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td><div>

Default values for CNPG clusters. See `example-postgredb.cluster` for reference. With this field you can configure common values for all CNPG clusters, e.g. backup location and schedule.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.common.postgres.defaultClusterTemplate</td>
		<td>tpl/string</td>
		<td>
<pre style="max-width:500px; overflow-x:auto; white-space: pre;" lang="tpl"><code>qvantelGlue.dbs.common.postgres.defaultClusterTemplate: |
  {{- if eq $.addonOperator.vaultPlatformEnabled "true" }}
  vaultConfiguration: true
  {{- end }}
  {{- if ne $.root.Values.global.configurationProfile "dev" }}
  barmanObjectStore:
    scheduledBackup: "0 0 * * *"
    spec:
      retentionPolicy: "7d"
      configuration:
        s3Credentials:
          {{- if eq $.addonOperator.awsPlatformEnabled "true" }}
          inheritFromIAMRole: true
          {{- end }}
        wal:
          compression: gzip
          maxParallel: 8
          encryption: AES256
  {{- end }} 
  spec:
    {{- if or (not $.cluster.spec) (not $.cluster.spec.imageName) }}
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
    {{- if $.cluster.barmanObjectStore }}
    plugins:
    - name: barman-cloud.cloudnative-pg.io
      isWALArchiver: true
      parameters:
        barmanObjectName: {{ $.clusterName }}-objectstore
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
        cpu: "0.1"
    storage:
      size: 10Gi
    {{- if eq $.addonOperator.monitoringPlatformEnabled "true" }}
    monitoring:
      podMonitorEnabled: true
      customQueriesConfigMap:
        - name: cnpg-queries-insights-metrics
          key: custom-metrics-queries
        {{- if and $.cluster.spec $.cluster.spec.postgresql $.cluster.spec.postgresql.parameters (hasKey $.cluster.spec.postgresql.parameters "pg_partman_bgw.dbname") }}
        - name: cnpg-partitions-alerts-{{ $.clusterName }}
          key: partitions-alerts-queries
        {{- end }}
        {{- if $.additionalCustomQueriesConfigMaps }}
        {{- range $k, $v := $.additionalCustomQueriesConfigMaps }}
        - name: {{ $k }}
        {{ $v | toYaml | indent 2 }}
        {{- end }}
        {{- end }}
    {{- end }}
    {{- if or (not $.cluster.spec) (not $.cluster.spec.bootstrap) }}
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
 
</code></pre>
</td>
		<td><div>

Default template for CNPG clusters. See `example-postgredb.cluster` for reference. This is templated field which is rendered for each cluster from `qvantelGlue.dbs.postgres`. With this field you can override default cluster template for complex cases and utilize helm templating in it. Scope for the template contains fields: 
 * addonOperator: content from Addon Operator configmap. You can check if some modules, e.f. monitoring-platform are enabled.
 * root: root context of 'qvantel-glue' module, containing all Values for the module.
 * cluster: content of 'cluster' field for rendered cluster.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.mariadb</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td><div>

MariaDB databases configuration. This is a map where each key corresponds to the MariaDB cluster  and associated configuration like dbs, roles and extensions.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.postgres</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td><div>

PostgreSQL databases configuration. This is a map where each key corresponds to the PostgreSQL cluster  and associated configuration like dbs, roles and extensions. For Example, see `example-postgredb` definition in Examples-PostgreSQL section below.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.sqlinstallersCrdSync</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
namespaceSelector:
    nameSelector:
        matchNames:
            - platform
schedule: '*/5 * * * *'</code></pre>
</td>
		<td><div>

Configuration for SqlInstaller CRDs reconciliation.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.sqlinstallersCrdSync.enabled</td>
		<td>bool</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
		<td><div>

Enables SqlInstaller CRDs reconciliation

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.sqlinstallersCrdSync.namespaceSelector</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - platform</code></pre>
</td>
		<td><div>

Selector for namespaces from which sync SqlInstaller resources. Default is `platform` namespace.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.sqlinstallersCrdSync.schedule</td>
		<td>string</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>'*/5 * * * *'</code></pre>
</td>
		<td><div>

Schedule for periodic reconciliation. Default is "*/5 * * * *" - so every 5 minutes.

</div>
</td>
	</tr>
	</tbody>
</table>

<h3>Examples-Cassandra</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;">example-cassandra</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cluster:
    spec: null
    vaultConfiguration: true
cqls:
    migration-tables:
        cql:
            - CREATE TABLE IF NOT EXISTS revenue_events.schema_versions ( version int, schema_type text, PRIMARY KEY (version, schema_type) ) WITH CLUSTERING ORDER BY (schema_type DESC);
dbs:
    messaging:
        cql:
            provision: "- \"CREATE KEYSPACE IF NOT EXISTS messaging WITH replication = {'class':'NetworkTopologyStrategy', 'DC1': 1} AND durable_writes = true;\"\n- \"ALTER KEYSPACE messaging WITH replication = {'class':'NetworkTopologyStrategy', 'DC1': 1} AND durable_writes = true;\"   \n"
    revenue-events:
        cql:
            additional:
                - CREATE TABLE IF NOT EXISTS revenue_events.schema_versions ( version int, schema_type text, PRIMARY KEY (version, schema_type) ) WITH CLUSTERING ORDER BY (schema_type DESC);
        replicationFactors: '{''class'':''NetworkTopologyStrategy'', ''DC1'': 1}'
        roles:
            apps-another-app-to-access-revenue-events:
                cql: |
                    CREATE USER '{{username}}' WITH PASSWORD '{{password}}' NOSUPERUSER; GRANT ALL PERMISSIONS ON KEYSPACE revenue_events TO {{username}};
roles:
    custom-role-access-all-keyspaces:
        cql: |
            CREATE USER '{{username}}' WITH PASSWORD '{{password}}' NOSUPERUSER; GRANT ALL PERMISSIONS ON ALL KEYSPACES TO {{username}};</code></pre>
</td>
			<td><div>

This is example Cassandra glue definition.  In this example CNPG cluster is configured with 3 dbs created in this cluster(`catalog-deployer`, `ddl`, `flex-bpmn-executor`) and few additional roles. Note: It is used for documentation purposes only. Real PostgreSQL clusters should be defined under `qvantelGlue.dbs.postgres`

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.cluster</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

Defines K8ssandra cluster (kind: K8ssandraCluster) to deploy.  If it is omitted, no cluster will be deployed as part of `glue` module and it is assumed cluster is deployed externally.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.cluster.spec</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

Configure K8ssandra cluster details. See https://docs.k8ssandra.io/reference/crd/k8ssandra-operator-crds-latest/#k8ssandraclusterspec for API reference.   

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.cluster.vaultConfiguration</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> by default equals to 'vaultPlatformEnabled' in addon-operator configmap, so if Vault module is enabled then 'true'</code></pre>
</td>
			<td><div>

Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.cqls</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Configures additional CqlInstallers for this cluster. Keys in this map will be used as Vault roles names.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.dbs</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Defines Databases (Keyspaces) to deploy in the K8ssandra Cluster. For each  database `CqlInstaller` is created which will execute Keyspace creation logic according to Qvantel conventions. This is a map where each key corresponds to the Keyspace to be created. If keyspace name contains hyphens (-) those will be replaced with underscores (_). E.g. in the following example `messaging` and `revenue_events` Keyspaces will be created.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.dbs.messaging.cql</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

It is possible to define provisioning CQL for the keyspace if customization is required.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.dbs.revenue-events.cql.additional</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

It is possible to define additional CQL for the keyspace initialization (handy if you want to keep keyspace creation logic default, but still to add something, like additional tables).

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.dbs.revenue-events.replicationFactors</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{'class':'NetworkTopologyStrategy', 'DC1': 1}</code></pre>
</td>
			<td><div>

Replication configuration for the Keyspace.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.dbs.revenue-events.roles</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Configures additional custom roles for this Keyspace in Vault. Keys in this map will be used as Vault roles names.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.roles</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Configures additional custom roles for this cluster in Vault. Keys in this map will be used as Vault roles names.

</div>
</td>
		</tr>
	</tbody>
</table>
<h3>Examples-PostgreSQL</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;">example-postgredb</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cluster:
    additionalLabels: {}
    annotations: {}
    barmanObjectStore:
        scheduledBackup: 0 0 * * *
        spec:
            configuration:
                s3Credentials:
                    inheritFromIAMRole: true
                wal:
                    compression: gzip
                    encryption: AES256
                    maxParallel: 8
            retentionPolicy: 7d
    scheduledBackup: 0 0 0 * * *
    spec:
        affinity:
            topologyKey: topology.kubernetes.io/zone
        enableSuperuserAccess: true
        imageName: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:15.7-1_7_master_b0ee48eda
        instances: 2
        postgresql:
            parameters:
                max_connections: "300"
                pg_stat_statements.max: "10000"
                pg_stat_statements.track: all
                random_page_cost: "1"
                wal_compression: pglz
            shared_preload_libraries:
                - timescaledb
        resources:
            requests:
                cpu: "0.1"
                memory: 1Gi
        storage:
            size: 10Gi
    vaultConfiguration: true
dbs:
    catalog-deployer:
        sql:
            provision: "- \"CREATE ROLE db_catalog_deployer NOLOGIN\"\n- \"GRANT db_catalog_deployer TO CURRENT_USER\"\n- \"CREATE DATABASE catalog_deployer WITH OWNER db_catalog_deployer\"    \n"
    ddl:
        extensions:
            timescaledb: {}
    flex-bpmn-executor:
        owners:
            apps-another-app-to-access-flex: {}
roles:
    custom-role-access-multiple-dbs:
        sql: |
            CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
            GRANT db_ddl TO "{{name}}";
            GRANT db_flex_bpmn_executor TO "{{name}}";
            ALTER ROLE "{{name}}" SET role db_ddl;
            ALTER ROLE "{{name}}" SET role db_flex_bpmn_executor;</code></pre>
</td>
			<td><div>

This is example PostgreSQL glue definition.  In this example CNPG cluster is configured with 3 dbs created in this cluster(`catalog-deployer`, `ddl`, `flex-bpmn-executor`) and few additional roles. Note: It is used for documentation purposes only. Real PostgreSQL clusters should be defined under `qvantelGlue.dbs.postgres`

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

Defines CNPG database cluster (kind: Cluster) to deploy.  If it is omitted, no cluster will be deployed as part of `glue` module and it is assumed cluster is deployed externally. Values configured in this object are merged with default template from `qvantelGlue.dbs.common.postgres.defaultClusterTemplate` and with default values from `qvantelGlue.dbs.common.postgres.defaultCluster`. Precedence is following defaultClusterTemplate <- defaultCluster <- cluster (values in this object). Cluster configuration follows same structure which is defined in [cnpg-postgres-platform](/modules/241-cnpg-postgres-platform/README.md) module.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster.additionalLabels</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> null</code></pre>
</td>
			<td><div>

Additional labels to be configured on cluster resource.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster.annotations</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> null</code></pre>
</td>
			<td><div>

Annotations to be configured on cluster resource.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster.barmanObjectStore.scheduledBackup</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> null</code></pre>
</td>
			<td><div>

Defines scheduled backup configuration as Cron string (e.g. "0 0 0 * * *" - every midnight). If configured, then (kind: ScheduledBackup) will be created for the cluster with provided schedule.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster.barmanObjectStore.spec</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> null</code></pre>
</td>
			<td><div>

Defines ObjectStore specification. See https://cloudnative-pg.io/plugin-barman-cloud/docs/plugin-barman-cloud.v1/#objectstorespec

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster.spec</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Configure CNPG cluster details. See https://cloudnative-pg.io/documentation/current/cloudnative-pg.v1/#postgresql-cnpg-io-v1-ClusterSpec for API reference.   

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster.vaultConfiguration</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> by default equals to 'vaultPlatformEnabled' in addon-operator configmap, so if Vault module is enabled then 'true'</code></pre>
</td>
			<td><div>

Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Defines Databases to deploy in the CNPG Cluster. For each  database `SqlInstaller` is created which will execute database creation logic according to Qvantel conventions.   This is a map where each key corresponds to the Database to be created. If Database name contains hyphens (-) those will be replaced with underscores (_).

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs.catalog-deployer.sql.provision</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

It is possible to define provisioning SQL for the database if customization is required.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs.ddl.extensions</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

Configures PostgreSQL extensions for database. Currently only `timescaledb` is supported.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs.ddl.extensions.timescaledb</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Enables `timescaledb` extensions for database.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs.flex-bpmn-executor.owners</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Additional owners roles to configure in Vault. Each key from this map will be added to Vault with database owner role.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.roles</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Configures additional custom roles for this cluster in Vault. Keys in this map will be used as Vault roles names.

</div>
</td>
		</tr>
	</tbody>
</table>

