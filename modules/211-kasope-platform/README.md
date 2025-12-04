

# kasope-platform


`kasope-platform` module is responsible for deployment of [K8ssandra Operator](https://docs.k8ssandra.io/components/k8ssandra-operator/) in the cluster.

Dependencies:
- Kubernetes version 1.26+
- [cert-manager](https://stash.qvantel.net/projects/CP/repos/k8s-platform-addon-operator/browse/modules/101-cert-platform/README.md) for K8ssandra Operator Webhook server cert

Provides:
- K8ssandra Operator for multi-cluster support
- Cass Operator for Cassandra cluster management
- Apache Cassandra 3.11.13 cluster named 'cluster' deployed by default
- Possibility to enable Medusa backups
- Automated secret creation for connection to Platform MinIO

Configured profiles:
- dev
  - 1 Cassandra node instead of default 3
  - 500Mi JVM heap instead of default 2Gi
  - 10Gi of storage instead of default 20Gi
  - requests only 1Gi of memory instead of default 4Gi


## Values

<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--clusters--cluster--spec">kasopePlatform.clusters.cluster.spec</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cassandra:
    config:
        cassandraYaml:
            num_tokens: 8
        jvmOptions:
            heapSize: 2Gi
    datacenters:
        - initContainers:
            - name: server-config-init
              resources:
                limits:
                    cpu: "0.5"
                    memory: 384M
                requests:
                    cpu: "0.1"
                    memory: 256M
          metadata:
            name: dc1
            services:
                allPodsService:
                    annotations:
                        consul.hashicorp.com/service-port: native
                dcService:
                    annotations:
                        consul.hashicorp.com/service-port: native
          perNodeConfigInitContainerImage: platform.artifactory.qvantel.net/k8s-platform-1-2-0/platform/platform-k8s-tools-minimal:1.3.3_202509080945_master_90384dcc
          racks:
            - name: default
          size: 3
          tolerations:
            - effect: NoSchedule
              key: dedicated-nodes
              operator: Equal
              value: platform-masters
    metadata:
        annotations:
            cassandra.datastax.com/allow-storage-changes: "true"
        services:
            allPodsService:
                annotations:
                    consul.hashicorp.com/service-port: native
            dcService:
                annotations:
                    consul.hashicorp.com/service-port: native
    resources:
        limits:
            memory: 8Gi
        requests:
            cpu: "0.1"
            memory: 4Gi
    serverImage: platform.artifactory.qvantel.net/k8s-platform-1-2-0/k8ssandra/cass-management-api:3.11.13
    serverVersion: 3.11.13
    serviceAccount: platform
    storageConfig:
        cassandraDataVolumeClaimSpec:
            accessModes:
                - ReadWriteOnce
            resources:
                requests:
                    storage: 20Gi
    telemetry:
        cassandra:
            endpoint:
                address: 0.0.0.0
            relabels:
                - action: drop
                  regex: ^org_apache_cassandra_metrics_table_cas_prepare_latency$|^org_apache_cassandra_metrics_table_cas_propose_latency$|^org_apache_cassandra_metrics_table_cas_commit_latency$|^org_apache_cassandra_metrics_table_view_read_time$|^org_apache_cassandra_metrics_table_view_lock_acquire_time$|^org_apache_cassandra_metrics_table_read_latency$|^org_apache_cassandra_metrics_table_coordinator_scan_latency$|^org_apache_cassandra_metrics_table_coordinator_read_latency$|^org_apache_cassandra_metrics_table_range_latency$|^org_apache_cassandra_metrics_table_write_latency$|^org_apache_cassandra_metrics_table_ss_tables_per_read$|^org_apache_cassandra_metrics_table_waiting_on_free_memtable_space$|^org_apache_cassandra_metrics_table_replica_filtering_protection_rows_cached_per_query$|^org_apache_cassandra_metrics_table_live_scanned$|^org_apache_cassandra_metrics_table_col_update_time_delta$|^org_apache_cassandra_metrics_cache_capacity$|^org_apache_cassandra_metrics_table_col_update_time_delta_histogram$|^org_apache_cassandra_metrics_table_live_scanned_histogram$|^org_apache_cassandra_metrics_table_ss_tables_per_read_histogram$|^org_apache_cassandra_metrics_table_estimated_partition_size_histogram$|^org_apache_cassandra_metrics_table_estimated_column_count_histogram$|^org_apache_cassandra_metrics_table_cas_prepare_total_latency$|^org_apache_cassandra_metrics_table_cas_commit_total_latency$|^org_apache_cassandra_metrics_table_cas_propose_total_latency$|^org_apache_cassandra_metrics_table_row_cache_hit_out_of_range$|^org_apache_cassandra_metrics_table_compression_metadata_off_heap_memory_used$|^org_apache_cassandra_metrics_table_bloom_filter_false_positives$|^org_apache_cassandra_metrics_table_bloom_filter_disk_space_used$|^org_apache_cassandra_metrics_table_all_memtables_live_data_size$|^org_apache_cassandra_metrics_table_all_memtables_heap_size$|^org_apache_cassandra_metrics_table_bytes_flushed$|^org_apache_cassandra_metrics_table_bloom_filter_off_heap_memory_used$|^org_apache_cassandra_metrics_table_recent_bloom_filter_false_positives$|^org_apache_cassandra_metrics_table_speculative_retries$|^org_apache_cassandra_metrics_table_key_cache_hit_rate$|^org_apache_cassandra_metrics_table_percent_repaired$|^org_apache_cassandra_metrics_table_row_cache_miss$|^org_apache_cassandra_metrics_table_short_read_protection_requests_total$|^org_apache_cassandra_metrics_table_recent_bloom_filter_false_ratio$|^org_apache_cassandra_metrics_table_col_update_time_delta_histogram_count$|^org_apache_cassandra_metrics_table_ss_tables_per_read_histogram_count$|^org_apache_cassandra_metrics_table_snapshots_size$|^org_apache_cassandra_metrics_table_row_cache_hit$|^org_apache_cassandra_metrics_table_replica_filtering_protection_requests_total$|^org_apache_cassandra_metrics_table_estimated_column_count_histogram_count$|^org_apache_cassandra_metrics_table_max_partition_size$|^org_apache_cassandra_metrics_table_range_total_latency$|^org_apache_cassandra_metrics_table_read_repair_requests_total$|^org_apache_cassandra_metrics_table_all_memtables_off_heap_size$|^org_apache_cassandra_metrics_table_bloom_filter_false_ratio$|^org_apache_cassandra_metrics_table_estimated_partition_size_histogram_count$|^org_apache_cassandra_metrics_table_compression_ratio$|^org_apache_cassandra_metrics_table_index_summary_off_heap_memory_used$|^org_apache_cassandra_metrics_table_live_scanned_histogram_count$|^org_apache_cassandra_metrics_table_mean_partition_size$|^org_apache_cassandra_metrics_table_memtable_live_data_size$|^org_apache_cassandra_metrics_table_memtable_columns_count$|^org_apache_cassandra_metrics_table_min_partition_size$|^org_apache_cassandra_metrics_keyspace_cas_commit_latency_bucket$|^org_apache_cassandra_metrics_keyspace_view_lock_acquire_time_bucket$|^org_apache_cassandra_metrics_keyspace_cas_propose_latency_bucket$|^org_apache_cassandra_metrics_keyspace_read_latency_bucket$|^org_apache_cassandra_metrics_keyspace_cas_prepare_latency_bucket$|^org_apache_cassandra_metrics_keyspace_view_read_time_bucket$|^org_apache_cassandra_metrics_keyspace_range_latency_bucket$|^org_apache_cassandra_metrics_keyspace_write_latency_bucket$|^org_apache_cassandra_metrics_dropped_message_internal_dropped_latency_bucket$|^org_apache_cassandra_metrics_dropped_message_cross_node_dropped_latency_bucket$|^org_apache_cassandra_metrics_keyspace_live_scanned_histogram$|^org_apache_cassandra_metrics_keyspace_ss_tables_per_read_histogram$|^org_apache_cassandra_metrics_keyspace_tombstone_scanned_histogram$|^org_apache_cassandra_metrics_keyspace_col_update_time_delta_histogram$
                  sourceLabels:
                    - __name__
        mcac:
            enabled: false
        prometheus:
            commonLabels:
                release: monitoring-platform
            enabled: true
reaper:
    autoScheduling:
        enabled: true</code></pre>
</td>
			<td><div>

Cassandra cluster spec section

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--clusters--cluster--spec--cassandra--serverImage">kasopePlatform.clusters.cluster.spec.cassandra.serverImage</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>platform.artifactory.qvantel.net/k8s-platform-1-2-0/k8ssandra/cass-management-api:3.11.13</code></pre>
</td>
			<td><div>

Setting serverImage to override the value coming from k8ssandra-operator.global.imageconfig.types

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator">kasopePlatform.k8ssandra-operator</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cass-operator:
    admissionWebhooks:
        enabled: false
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    serviceAccount:
        create: false
        name: platform
cleaner:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
disableCrdUpgraderJob: true
enabled: true
global:
    clusterScoped: true
    imageConfig:
        defaults:
            registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        images:
            config-builder:
                name: cass-config-builder
                repository: datastax
                tag: 1.0-ubi8
            k8ssandra-client:
                name: k8ssandra-client
                repository: k8ssandra
                tag: v0.8.3
            medusa:
                name: medusa
                repository: k8ssandra
                tag: 0.25.1
            reaper:
                name: cassandra-reaper
                repository: thelastpickle
                tag: 4.0.0
            system-logger:
                name: system-logger
                repository: k8ssandra
                tag: v1.27.1
        types:
            cassandra:
                name: cass-management-api
                repository: k8ssandra
                suffix: -ubi8
image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
serviceAccount:
    create: false
    name: platform</code></pre>
</td>
			<td><div>

Configuration for underlying k8ssandra-operator helm-chart. See https://github.com/k8ssandra/k8ssandra-operator/tree/main/charts/k8ssandra-operator

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator--cass-operator">kasopePlatform.k8ssandra-operator.cass-operator</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>admissionWebhooks:
    enabled: false
image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
serviceAccount:
    create: false
    name: platform</code></pre>
</td>
			<td><div>

Configuration for underlying cass-operator helm-chart. See https://github.com/k8ssandra/k8ssandra/tree/main/charts/cass-operator

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator--disableCrdUpgraderJob">kasopePlatform.k8ssandra-operator.disableCrdUpgraderJob</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

CRD Upgrader is disabled by default as we manage CRDs ourselves

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator--enabled">kasopePlatform.k8ssandra-operator.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

In clusters where we can't or won't deploy operators, then this can be set to false.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator--global--imageConfig">kasopePlatform.k8ssandra-operator.global.imageConfig</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>defaults:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
images:
    config-builder:
        name: cass-config-builder
        repository: datastax
        tag: 1.0-ubi8
    k8ssandra-client:
        name: k8ssandra-client
        repository: k8ssandra
        tag: v0.8.3
    medusa:
        name: medusa
        repository: k8ssandra
        tag: 0.25.1
    reaper:
        name: cassandra-reaper
        repository: thelastpickle
        tag: 4.0.0
    system-logger:
        name: system-logger
        repository: k8ssandra
        tag: v1.27.1
types:
    cassandra:
        name: cass-management-api
        repository: k8ssandra
        suffix: -ubi8</code></pre>
</td>
			<td><div>

Setting new imageConfig from k8ssandra-operator 1.27.0

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--mainCassandraCluster">kasopePlatform.mainCassandraCluster</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cluster</code></pre>
</td>
			<td><div>

Name of the cassandra cluster used as a backend for main-cassandra-service. See [main-service](templates/main-service.yaml)

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--vaultConfiguration">kasopePlatform.vaultConfiguration</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

If true, will create DbConnection and DbRoles. See [cassandra-vault](templates/cassandra-vault.yaml)

</div>
</td>
		</tr>
	</tbody>
</table>

