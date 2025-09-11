

# cnpg-postgres-platform

This module is responsible for deployment of [CNPG Operator](https://cloudnative-pg.io/documentation/current/) and managed PostgresSQL clusters.

Depends on modules:
- [platform-core](/modules/101-platform-core/README.md) from which *platform* Service Account is used

Provides:
- CNPG Operator deployment
- Configuration of postgres cluster CRDs (postgresql.cnpg.io/v1)

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
		<td style="width: 300px;">cnpgPostgresPlatform.cloudnative-pg</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>additionalEnv:
    - name: EXPIRING_CHECK_THRESHOLD
      value: "30"
crds:
    create: false
enabled: true
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/cloudnative-pg/cloudnative-pg
serviceAccount:
    create: false
    name: platform
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
		<td><div>

Configuration for CNPG operator helm chart. See https://github.com/cloudnative-pg/charts/tree/main/charts/cloudnative-pg for API reference.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">cnpgPostgresPlatform.clusters</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>qvt-postgredb: {}</code></pre>
</td>
		<td><div>

CNPG clusters configuration. This is a map where each key corresponds to the PostgreSQL cluster to be provisioned For Example, see `example-postgredb` definition in Examples-PostgreSQL section below. By default cluster 'qvt-postgredb' is defined and provisioned with default configuration.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">cnpgPostgresPlatform.common</td>
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
		<td style="width: 300px;">cnpgPostgresPlatform.common.defaultCluster</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td><div>

Default values for CNPG clusters. See `example-postgredb` for reference. With this field you can configure common values for all CNPG clusters, e.g. backup location and schedule.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">cnpgPostgresPlatform.common.defaultClusterTemplate</td>
		<td>tpl/string</td>
		<td>
<pre style="max-width:500px; overflow-x:auto; white-space: pre;" lang="tpl"><code>cnpgPostgresPlatform.common.defaultClusterTemplate: |
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

Default spec for CNPG clusters. See `example-postgredb` for reference. This is templated field which is rendered for each cluster from `cnpgPostgresPlatform.clusters`.  With this field you can override default cluster template for complex cases and utilize helm templating in it. Scope for the template contains fields: 
 * addonOperator: content from Addon Operator configmap. You can check if some modules, e.f. monitoring-platform are enabled.
 * root: root context of 'qvantel-glue' module, containing all Values for the module.
 * cluster: content of 'cluster' field for rendered cluster.

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
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>additionalLabels: {}
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
spec:
    affinity:
        nodeSelector:
            dedicated-nodes: platform-masters
        tolerations:
            - effect: NoSchedule
              key: dedicated-nodes
              operator: Equal
              value: platform-masters
        topologyKey: topology.kubernetes.io/zone
    instances: 2
    storage:
        size: 10Gi
vaultConfiguration: true</code></pre>
</td>
			<td><div>

This is example PostgreSQL cluster definition.  Note: It is used for documentation purposes only. Real PostgreSQL clusters should be defined under `cnpgPostgresPlatform.clusters` Values configured in this object are merged with default template from `cnpgPostgresPlatform.common.defaultClusterTemplate` and with default values from `cnpgPostgresPlatform.common.defaultCluster`. Precedence is following defaultClusterTemplate <- defaultCluster <- cluster (values in this object).

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.additionalLabels</td>
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
			<td style="width: 300px;">example-postgredb.annotations</td>
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
			<td style="width: 300px;">example-postgredb.barmanObjectStore</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> null</code></pre>
</td>
			<td><div>

Barman ObjectStore related configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.barmanObjectStore.scheduledBackup</td>
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
			<td style="width: 300px;">example-postgredb.barmanObjectStore.spec</td>
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
			<td style="width: 300px;">example-postgredb.spec</td>
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
			<td style="width: 300px;">example-postgredb.vaultConfiguration</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>by default equals to 'vaultPlatformEnabled' in addon-operator configmap, so if Vault module is enabled then 'true'</code></pre>
</td>
			<td><div>

Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.

</div>
</td>
		</tr>
	</tbody>
</table>

