kasopePlatform:
  k8ssandra-operator:
    image:
      registry: ${values['global']['containerRegistryBase']}
      
    client:
      image:
        registry: ${values['global']['containerRegistryBase']}
        tag: "1.6.0-20240506112248-96d77628"
    cleaner:
      image:
        registry: ${values['global']['containerRegistryBase']}
    cass-operator:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repositoryOverride: 
          cassandra:
            "3.11.13": ${values['global']['containerRegistryBase']}/k8ssandra/cass-management-api:3.11.13
      imageConfig:
        systemLogger: ${values['global']['containerRegistryBase']}/k8ssandra/system-logger:v1.19.1
        configBuilder: ${values['global']['containerRegistryBase']}/datastax/cass-config-builder:1.0-ubi8
        k8ssandraClient: ${values['global']['containerRegistryBase']}/k8ssandra/k8ssandra-client/v0.2.2
      admissionWebhooks:
        enabled: false
    disableCrdUpgraderJob: true
  vaultConfiguration: true
  mainCassandraCluster: "cluster"
  clusters:
    cluster:
      enabled: true    
      spec:
        cassandra:
          serviceAccount: platform
          serverVersion: "3.11.13"
          metadata:
            services:
              dcService:
                annotations:
                  consul.hashicorp.com/service-port: native
              allPodsService:
                annotations:
                  consul.hashicorp.com/service-port: native
          config:
            cassandraYaml:
              num_tokens: 8            
            jvmOptions:
              % if values['global']['configurationProfile'] in {'dev'}: 
              heapSize: 500Mi
              % else:
              heapSize: 2Gi
              % endif              
          storageConfig:
            cassandraDataVolumeClaimSpec:
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  % if values['global']['configurationProfile'] in {'dev'}: 
                  storage: 10Gi
                  % else:
                  storage: 100Gi
                  % endif
          % if values['global']['configurationProfile'] in {'dev'}: 
          resources:
            requests:
              memory: 1Gi
              cpu: "0.1"
            limits:
              memory: 8Gi 
          % else:
          resources:
            requests:
              memory: 4Gi
              cpu: "0.1"
            limits:
              memory: 8Gi 
          % endif
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
              % if values['global']['configurationProfile'] in {'dev'}: 
              size: 1
              % else:
              size: 3
              % endif              
              perNodeConfigInitContainerImage: ${values['global']['containerRegistryBase']}/platform/platform-k8s-tools-minimal:1.2.0_4_20c54b53f
              racks:
                - name: default
                  % if values['global']['platformMasters']:
                  nodeAffinityLabels:
                    dedicated-nodes: platform-masters
                  % endif
              tolerations:
                - effect: NoSchedule
                  key: dedicated-nodes
                  operator: Equal
                  value: platform-masters
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
          containerImage:
            name: "cassandra-reaper"
            registry: ${values['global']['containerRegistryBase']}
            tag: "3.5.0"
          initContainerImage:
            name: "cassandra-reaper"
            registry: ${values['global']['containerRegistryBase']}
            tag: "3.5.0"
