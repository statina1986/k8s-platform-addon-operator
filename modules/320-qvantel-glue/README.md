

# qvantel-glue

<!-- BRIEF -->
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

Enables CqlInstaller CRDs reconciliation

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

Selector for namespaces from which sync CqlInstaller resources. Default is `platform` namespace.

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
		<td style="width: 300px;">qvantelGlue.dbs.common.cassandra</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>see child items docs</code></pre>
</td>
		<td><div>

Common configurations for Cassandra databases

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.common.cassandra.defaultCluster</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td><div>

Default values for Cassandra clusters. See `example-cassandra.cluster` for reference. With this field you can configure common values for all Cassandra clusters, e.g. backup location and schedule.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.common.cassandra.defaultClusterTemplate</td>
		<td>tpl/string</td>
		<td>
<pre style="max-width:500px; overflow-x:auto; white-space: pre;" lang="tpl"><code>qvantelGlue.dbs.common.cassandra.defaultClusterTemplate: |
  {{- if eq $.addonOperator.vaultPlatformEnabled "true" }}
  vaultConfiguration: true
  {{- end }}
  medusaBackupSchedule: "05 02 * * *"
  medusaBackupType: differential
  snaphotCleanerSchedule: "0 0 1 * *"
  spec:
    cassandra:
      serviceAccount: platform
      serverVersion: "4.1.8"
      serverImage: "{{$.root.Values.global.containerRegistryBase | default "docker.io"}}/k8ssandra/cass-management-api:4.1.8-ubi8"
      metadata:
        annotations:
          cassandra.datastax.com/allow-storage-changes: 'true'
        services:
          dcService:
            annotations:
              consul.hashicorp.com/service-port: native
          allPodsService:
            annotations:
              consul.hashicorp.com/service-port: native
      config:
        cassandraYaml:
          num_tokens: 16
          materialized_views_enabled: true
        jvmOptions:
          {{- if eq $.root.Values.global.configurationProfile "dev" }} 
          heapSize: 500Mi
          {{- else }}
          heapSize: 2Gi
          {{- end }}
      storageConfig:
        cassandraDataVolumeClaimSpec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              {{- if eq $.root.Values.global.configurationProfile "dev" }}
              storage: 10Gi
              {{- else }}
              storage: 20Gi
              {{- end }}      
      {{- if eq $.root.Values.global.configurationProfile "dev" }}
      resources:
        requests:
          memory: 1Gi
          cpu: "0.1"
        limits:
          memory: 8Gi
      {{- else }}
      resources:
        requests:
          memory: 4Gi
          cpu: "0.1"
        limits:
          memory: 8Gi
      {{- end }}
      datacenters:
        - metadata:
            name: dc1
            services:
              dcService:
                annotations:
                  consul.hashicorp.com/service-port: native
              allPodsService:
                annotations:
                  consul.hashicorp.com/service-port: native 
          {{- if eq $.root.Values.global.configurationProfile "dev" }}
          size: 1
          {{- else }}
          size: 3
          {{- end }}
          # Universal limits for init containers
          initContainers:
          - name: server-config-init
            resources:
              limits:
                cpu: '0.5'
                memory: 384M
              requests:
                cpu: '0.1'
                memory: 256M
          perNodeConfigInitContainerImage: {{$.root.Values.global.containerRegistryBase | default "platform.artifactory.qvantel.net"}}/platform/platform-k8s-tools-minimal:1.3.3_202509080945_master_90384dcc
         
          racks:
            - name: default
              {{- if $.root.Values.global.platformMasters }}
              nodeAffinityLabels:
                {{ $.root.Values.global.platformMastersKey }}: {{ $.root.Values.global.platformMastersValue }}
              {{- end }}
          tolerations:
            - effect: NoSchedule
              key: {{ $.root.Values.global.platformMastersKey }}
              operator: Equal
              value: {{ $.root.Values.global.platformMastersValue }}
      telemetry:
        cassandra:
          endpoint:
            address: "0.0.0.0"
          relabels:
            - action: drop
              regex: ^org_apache_cassandra_metrics_table_cas_prepare_latency$|^org_apache_cassandra_metrics_table_cas_propose_latency$|^org_apache_cassandra_metrics_table_cas_commit_latency$|^org_apache_cassandra_metrics_table_view_read_time$|^org_apache_cassandra_metrics_table_view_lock_acquire_time$|^org_apache_cassandra_metrics_table_read_latency$|^org_apache_cassandra_metrics_table_coordinator_scan_latency$|^org_apache_cassandra_metrics_table_coordinator_read_latency$|^org_apache_cassandra_metrics_table_range_latency$|^org_apache_cassandra_metrics_table_write_latency$|^org_apache_cassandra_metrics_table_ss_tables_per_read$|^org_apache_cassandra_metrics_table_waiting_on_free_memtable_space$|^org_apache_cassandra_metrics_table_replica_filtering_protection_rows_cached_per_query$|^org_apache_cassandra_metrics_table_live_scanned$|^org_apache_cassandra_metrics_table_col_update_time_delta$|^org_apache_cassandra_metrics_cache_capacity$|^org_apache_cassandra_metrics_table_col_update_time_delta_histogram$|^org_apache_cassandra_metrics_table_live_scanned_histogram$|^org_apache_cassandra_metrics_table_ss_tables_per_read_histogram$|^org_apache_cassandra_metrics_table_estimated_partition_size_histogram$|^org_apache_cassandra_metrics_table_estimated_column_count_histogram$|^org_apache_cassandra_metrics_table_cas_prepare_total_latency$|^org_apache_cassandra_metrics_table_cas_commit_total_latency$|^org_apache_cassandra_metrics_table_cas_propose_total_latency$|^org_apache_cassandra_metrics_table_row_cache_hit_out_of_range$|^org_apache_cassandra_metrics_table_compression_metadata_off_heap_memory_used$|^org_apache_cassandra_metrics_table_bloom_filter_false_positives$|^org_apache_cassandra_metrics_table_bloom_filter_disk_space_used$|^org_apache_cassandra_metrics_table_all_memtables_live_data_size$|^org_apache_cassandra_metrics_table_all_memtables_heap_size$|^org_apache_cassandra_metrics_table_bytes_flushed$|^org_apache_cassandra_metrics_table_bloom_filter_off_heap_memory_used$|^org_apache_cassandra_metrics_table_recent_bloom_filter_false_positives$|^org_apache_cassandra_metrics_table_speculative_retries$|^org_apache_cassandra_metrics_table_key_cache_hit_rate$|^org_apache_cassandra_metrics_table_percent_repaired$|^org_apache_cassandra_metrics_table_row_cache_miss$|^org_apache_cassandra_metrics_table_short_read_protection_requests_total$|^org_apache_cassandra_metrics_table_recent_bloom_filter_false_ratio$|^org_apache_cassandra_metrics_table_col_update_time_delta_histogram_count$|^org_apache_cassandra_metrics_table_ss_tables_per_read_histogram_count$|^org_apache_cassandra_metrics_table_snapshots_size$|^org_apache_cassandra_metrics_table_row_cache_hit$|^org_apache_cassandra_metrics_table_replica_filtering_protection_requests_total$|^org_apache_cassandra_metrics_table_estimated_column_count_histogram_count$|^org_apache_cassandra_metrics_table_max_partition_size$|^org_apache_cassandra_metrics_table_range_total_latency$|^org_apache_cassandra_metrics_table_read_repair_requests_total$|^org_apache_cassandra_metrics_table_all_memtables_off_heap_size$|^org_apache_cassandra_metrics_table_bloom_filter_false_ratio$|^org_apache_cassandra_metrics_table_estimated_partition_size_histogram_count$|^org_apache_cassandra_metrics_table_compression_ratio$|^org_apache_cassandra_metrics_table_index_summary_off_heap_memory_used$|^org_apache_cassandra_metrics_table_live_scanned_histogram_count$|^org_apache_cassandra_metrics_table_mean_partition_size$|^org_apache_cassandra_metrics_table_memtable_live_data_size$|^org_apache_cassandra_metrics_table_memtable_columns_count$|^org_apache_cassandra_metrics_table_min_partition_size$|^org_apache_cassandra_metrics_keyspace_cas_commit_latency_bucket$|^org_apache_cassandra_metrics_keyspace_view_lock_acquire_time_bucket$|^org_apache_cassandra_metrics_keyspace_cas_propose_latency_bucket$|^org_apache_cassandra_metrics_keyspace_read_latency_bucket$|^org_apache_cassandra_metrics_keyspace_cas_prepare_latency_bucket$|^org_apache_cassandra_metrics_keyspace_view_read_time_bucket$|^org_apache_cassandra_metrics_keyspace_range_latency_bucket$|^org_apache_cassandra_metrics_keyspace_write_latency_bucket$|^org_apache_cassandra_metrics_dropped_message_internal_dropped_latency_bucket$|^org_apache_cassandra_metrics_dropped_message_cross_node_dropped_latency_bucket$|^org_apache_cassandra_metrics_keyspace_live_scanned_histogram$|^org_apache_cassandra_metrics_keyspace_ss_tables_per_read_histogram$|^org_apache_cassandra_metrics_keyspace_tombstone_scanned_histogram$|^org_apache_cassandra_metrics_keyspace_col_update_time_delta_histogram$
              sourceLabels:
                - __name__
        prometheus:
          enabled: true
          commonLabels:
            release: monitoring-platform
        mcac:
          enabled: false
    reaper:
      autoScheduling:
        enabled: true
 
</code></pre>
</td>
		<td><div>

Default template for Cassandra clusters. See `example-cassandra.cluster` for reference. This is templated field which is rendered for each cluster from `qvantelGlue.dbs.cassandra`. With this field you can override default cluster template for complex cases and utilize helm templating in it. Scope for the template contains fields: 
 * addonOperator: content from Addon Operator configmap. You can check if some modules, e.f. monitoring-platform are enabled.
 * root: root context of 'qvantel-glue' module, containing all Values for the module.
 * cluster: content of 'cluster' field for rendered cluster.

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
    {{- if eq $.addonOperator.monitoringPlatformEnabled "true" }}
      performance_schema=on
 
      # statements consumers
      performance-schema-consumer-events-statements-current=ON
      performance-schema-consumer-events-statements-history=ON
      performance-schema-consumer-events-statements-history-long=ON
      performance-schema-consumer-statements-digest=ON
 
      # waits consumers
      performance-schema-consumer-events-waits-current=ON
      performance-schema-consumer-events-waits-history=ON
      performance-schema-consumer-events-waits-history-long=ON
 
      # stages consumers
      performance-schema-consumer-events-stages-current=ON
      performance-schema-consumer-events-stages-history=ON
      performance-schema-consumer-events-stages-history-long=ON
 
      # hold long history
      # performance_schema_events_statements_history_long_size=10000
      # performance_schema_events_waits_history_long_size=10000
    {{- end }}
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        memory: 1Gi 
  defaultSqlExporter:
    service:
      port: 9399
    # Main config for sql_exporter. DSN is injected at runtime by init container.
    config:
      content: |
        global:
          scrape_timeout_offset: 500ms
        target:
          # DSN injected by init container via placeholder substitution
          data_source_name: "__DSN__"
          collectors:
            - mariadb_custom
        collectors:
          - collector_name: mariadb_custom
            metrics:
              - metric_name: mariadb_threads_connected
                type: gauge
                help: Number of currently open connections
                values: [threads_connected]
                query: |
                  SELECT VARIABLE_VALUE AS threads_connected
                  FROM information_schema.GLOBAL_STATUS
                  WHERE VARIABLE_NAME = 'Threads_connected'
 
              - metric_name: mariadb_uptime_seconds
                type: gauge
                help: Server uptime in seconds
                values: [uptime]
                query: |
                  SELECT VARIABLE_VALUE AS uptime
                  FROM INFORMATION_SCHEMA.GLOBAL_STATUS
                  WHERE VARIABLE_NAME = 'UPTIME'
 
              - metric_name: _anchor_only_exec_query
                type: gauge
                help: "Anchor row to define &mariadb_exec_query (ignored by scraper if not referenced)"
                values: [exec_count]
                query: &mariadb_exec_query |
                  SELECT
                    sd.DIGEST                                   AS query_id,
                    sd.DIGEST_TEXT                              AS query,
                    COALESCE(sd.SCHEMA_NAME, 'unknown')         AS database_name,
                    sd.COUNT_STAR                                AS exec_count,
                    ROUND(sd.SUM_TIMER_WAIT / 1e12, 6)           AS total_exec_time_sec,
                    ROUND(sd.AVG_TIMER_WAIT / 1e12, 6)           AS avg_exec_time_sec,
                    ROUND(sd.MAX_TIMER_WAIT / 1e12, 6)           AS max_exec_time_sec,
                    ROUND(sd.SUM_TIMER_WAIT / 1e9,  3)           AS stmt_total_latency_ms,
                    sd.LAST_SEEN                                  AS last_seen
                  FROM performance_schema.events_statements_summary_by_digest AS sd
                  WHERE sd.DIGEST_TEXT IS NOT NULL
                  ORDER BY sd.SUM_TIMER_WAIT DESC
                  LIMIT 100;
 
              - metric_name: _anchor_only_waits_query
                type: gauge
                help: "Anchor row to define &mariadb_waits_query (ignored by scraper if not referenced)"
                values: [wait_count]
                query: &mariadb_waits_query |
                  SELECT
                    w.EVENT_NAME                                                     AS wait_event_name,
                    SUBSTRING_INDEX(w.EVENT_NAME, '/', 1)                            AS event_type,
                    SUBSTRING_INDEX(SUBSTRING_INDEX(w.EVENT_NAME,'/',3), '/', -2)    AS event_subtype,
                    w.COUNT_STAR                                                     AS wait_count,
                    ROUND(w.SUM_TIMER_WAIT / 1e12, 6)                                AS total_wait_sec,
                    ROUND(w.AVG_TIMER_WAIT / 1e12, 6)                                AS avg_wait_sec,
                    ROUND(w.MAX_TIMER_WAIT / 1e12, 6)                                AS max_wait_sec
                  FROM performance_schema.events_waits_summary_global_by_event_name AS w
                  HAVING wait_event_name <> 'idle'
                  ORDER BY w.SUM_TIMER_WAIT DESC
                  LIMIT 100;
 
              - metric_name: mariadb_wait_event_sample_total
                type: gauge
                help: Number of wait-event samples observed (global, by event)
                key_labels: [wait_event_name, event_type, event_subtype]
                values: [wait_count]
                query: *mariadb_waits_query
 
              - metric_name: mariadb_wait_event_total_seconds
                type: gauge
                help: Cumulative wait time spent in an event (seconds)
                key_labels: [wait_event_name, event_type, event_subtype]
                values: [total_wait_sec]
                query: *mariadb_waits_query
 
              - metric_name: mariadb_wait_event_average_seconds
                type: gauge
                help: Average wait time per sample for an event (seconds)
                key_labels: [wait_event_name, event_type, event_subtype]
                values: [avg_wait_sec]
                query: *mariadb_waits_query
 
              - metric_name: mariadb_wait_event_max_seconds
                type: gauge
                help: Maximum wait time observed for an event (seconds)
                key_labels: [wait_event_name, event_type, event_subtype]
                values: [max_wait_sec]
                query: *mariadb_waits_query
 
              - metric_name: mariadb_wait_event_exec_count
                type: gauge
                help: Number of statement executions (by digest)
                key_labels: [query_id, query, database_name]
                values: [exec_count]
                query: *mariadb_exec_query
 
              - metric_name: mariadb_wait_event_stmt_total_latency
                type: gauge
                help: Total statement latency (milliseconds, by digest)
                key_labels: [query_id, query, database_name]
                values: [stmt_total_latency_ms]
                query: *mariadb_exec_query
 
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
  {{- if eq $.addonOperator.shutdownOperatorEnabled "true" }}
  enablePDB: false
  {{- end }}
  {{- if ne $.root.Values.global.configurationProfile "dev" }}
  barmanObjectStore:
    scheduledBackup: "0 0 0 * * *"
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
      major: 18
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
    {{- if $.root.Values.global.gcpRole }}
    serviceAccountTemplate:
      metadata:
        annotations:
          iam.gke.io/gcp-service-account: {{ $.root.Values.global.gcpRole }}
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

MariaDB databases configuration. This is a map where each key corresponds to the MariaDB cluster  and associated configuration like dbs, roles and extensions. For Example, see `example-mariadb` definition in Examples-MariaDB section below.

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
		<td style="width: 300px;">qvantelGlue.dbs.rabbitmq</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td><div>

RabbitMQ vhosts configuration. This is a map where each key corresponds to the dedicated vhost  and associated configuration like roles and permissions. For Example, see `example-rabbitmq` definition in Examples-RabbitMQ section below.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.shellinstallersCrdSync.enabled</td>
		<td>bool</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
		<td><div>

Enables ShellInstaller CRDs reconciliation

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.shellinstallersCrdSync.namespaceSelector</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - platform</code></pre>
</td>
		<td><div>

Selector for namespaces from which sync ShellInstaller resources. Default is `platform` namespace.

</div>
</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.shellinstallersCrdSync.schedule</td>
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
    mainCassandraCluster: ""
    medusaBackupSchedule: 05 02 * * *
    medusaBackupType: differential
    snaphotCleanerSchedule: 0 0 1 * *
    spec:
        cassandra:
            datacenters:
                - metadata:
                    name: dc3
                  size: 1
            storageConfig:
                cassandraDataVolumeClaimSpec:
                    StorageClassName: local-path
                    accessModes:
                        - ReadWriteOnce
                    resources:
                        requests:
                            storage: 50Gi
        medusa:
            storageProperties:
                prefix: example-cassandra
        reaper:
            datacenterAvailability: LOCAL
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

This is example Cassandra glue definition.  In this example Cassandra cluster is configured with 2 keyspaces created in this cluster(`messaging`,`revenue_events`) and few additional roles. Note: It is used for documentation purposes only. Real Cassandra clusters should be defined under `qvantelGlue.dbs.cassandra`

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

Defines K8ssandra cluster (kind: K8ssandraCluster) to deploy.  Values configured in this object are merged with default template from `qvantelGlue.dbs.common.cassandra.defaultClusterTemplate` and with default values from `qvantelGlue.dbs.common.cassandra.defaultCluster`. Precedence is following defaultClusterTemplate <- defaultCluster <- cluster (values in this object).

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.cluster.mainCassandraCluster</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

Name of the cassandra cluster used as a backend for main-cassandra-service. See [main-service](templates/cassandra-dbs.yaml.mako)

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.cluster.medusaBackupSchedule</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> "05 02 * * *"</code></pre>
</td>
			<td><div>

Sets time for when to take Medusa backup, if medusa is configured under cluster.spec.medusa

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.cluster.medusaBackupType</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>"differential"</code></pre>
</td>
			<td><div>

Sets type for Medusa backup, if medusa is configured under cluster.spec.medusa

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.cluster.snaphotCleanerSchedule</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> "0 0 1 * *"</code></pre>
</td>
			<td><div>

Sets time for when to run snapshot-cleaner cronjob. Runs 'nodetool clearsnapshot --all' against each Cassandra pod in a cluster

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-cassandra.cluster.spec</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cassandra:
    datacenters:
        - metadata:
            name: dc3
          size: 1
    storageConfig:
        cassandraDataVolumeClaimSpec:
            StorageClassName: local-path
            accessModes:
                - ReadWriteOnce
            resources:
                requests:
                    storage: 50Gi
medusa:
    storageProperties:
        prefix: example-cassandra
reaper:
    datacenterAvailability: LOCAL</code></pre>
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
<h3>Examples-MariaDB</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;">example-mariadb</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cluster:
    additionalLabels: {}
    annotations: {}
    spec:
        storage:
            size: 1Gi
    vaultConfiguration: true
dbs:
    mnp-gw:
        namespace: mnp
        owners:
            apps-another-app-to-access-mnp: {}
        sql:
            provision: |
                - "<custom SQL goes here>"
                - "<custom SQL goes here>"
roles:
    custom-role-access-multiple-dbs:
        sql: |
            <custom Vault templated SQL goes here></code></pre>
</td>
			<td><div>

This is example MariaDB glue definition.  In this example MariaDB cluster is configured with 1 db created in this cluster(`mnp-gw`) and few additional roles. Note: It is used for documentation purposes only. Real MariaDB clusters should be defined under `qvantelGlue.db.mariadb`

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-mariadb.cluster</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

Defines MariaDB database cluster (kind: MariaDB) to deploy.  Values configured in this object are merged with default template from `qvantelGlue.dbs.common.mariadb.defaultClusterTemplate` and with default values from `qvantelGlue.dbs.common.mariadb.defaultCluster`. Precedence is following defaultClusterTemplate <- defaultCluster <- cluster (values in this object).

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-mariadb.cluster.additionalLabels</td>
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
			<td style="width: 300px;">example-mariadb.cluster.annotations</td>
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
			<td style="width: 300px;">example-mariadb.cluster.spec</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Configure MariaDB cluster details. See https://github.com/mariadb-operator/mariadb-operator/blob/main/docs/api_reference.md#mariadb for API reference.   

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-mariadb.cluster.vaultConfiguration</td>
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
			<td style="width: 300px;">example-mariadb.dbs</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td><div>

Defines Databases to deploy in the MariaDB Cluster. For each  database `SqlInstaller` is created which will execute database creation logic according to Qvantel conventions.   This is a map where each key corresponds to the Database to be created. If Database name contains hyphens (-) those will be replaced with underscores (_).

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-mariadb.dbs.mnp-gw.namespace</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

Specify namespace for the database. Default Vault roles will be generated with this namespace in mind. When not specified value from `Values.global.appsNamespace` is used. 

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-mariadb.dbs.mnp-gw.owners</td>
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
			<td style="width: 300px;">example-mariadb.dbs.mnp-gw.sql.provision</td>
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
			<td style="width: 300px;">example-mariadb.roles</td>
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
        scheduledBackup: 0 0 0 * * *
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
    mnp-gw:
        namespace: mnp-gw
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

Defines CNPG database cluster (kind: Cluster) to deploy.  Values configured in this object are merged with default template from `qvantelGlue.dbs.common.postgres.defaultClusterTemplate` and with default values from `qvantelGlue.dbs.common.postgres.defaultCluster`. Precedence is following defaultClusterTemplate <- defaultCluster <- cluster (values in this object).

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
			<td style="width: 300px;">example-postgredb.dbs.mnp-gw.namespace</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

Specify namespace for the database. Default Vault roles will be generated with this namespace in mind. When not specified value from `Values.global.appsNamespace` is used. 

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
<h3>Examples-RabbitMQ</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;">example-rabbitmq</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>namespace: mnp</code></pre>
</td>
			<td><div>

This is example RabbitMQ glue definition.  In this example RabbitMQ cluster is configured with vhost `example-rabbitmq`. Note: It is used for documentation purposes only. Real RabbitMQ vhosts should be defined under `qvantelGlue.dbs.rabbitmq`

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-rabbitmq.namespace</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td><div>

Specify namespace for the vhosts roles. Default Vault roles will be generated with this namespace in mind. When not specified value from `Values.global.appsNamespace` is used. 

</div>
</td>
		</tr>
	</tbody>
</table>

