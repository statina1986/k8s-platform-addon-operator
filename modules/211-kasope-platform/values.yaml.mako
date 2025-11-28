kasopePlatform:
  # -- Configuration for underlying k8ssandra-operator helm-chart. See https://github.com/k8ssandra/k8ssandra-operator/tree/main/charts/k8ssandra-operator
  k8ssandra-operator:    
    # -- In clusters where we can't or won't deploy operators, then this can be set to false.
    % if values['global']['deployOperators'] == "false":
    enabled: false
    % else:
    enabled: true
    % endif
    global:
      % if values['global']['clusterwideResources'] == "false":
      clusterScoped: false
      % else:
      clusterScoped: true
      % endif
      # -- Setting new imageConfig from k8ssandra-operator 1.27.0
      imageConfig:
        images:
          system-logger:
            repository: "k8ssandra"
            name: "system-logger"
            tag: "v1.27.1"
          config-builder:
            repository: "datastax"
            name: "cass-config-builder"
            tag: "1.0-ubi8"
          k8ssandra-client:
            repository: "k8ssandra"
            name: "k8ssandra-client"
            tag: "v0.8.3"
          reaper:
            repository: "thelastpickle"
            name: "cassandra-reaper"
            tag: "4.0.0"
          medusa:
            repository: "k8ssandra"
            name: "medusa"
            tag: "0.25.1"
        types:
          cassandra:
            repository: "k8ssandra"
            name: "cass-management-api"
            suffix: "-ubi8"
        % if 'containerRegistryBase' in values['global']:
        defaults:
          registry: ${values['global']['containerRegistryBase']}
        % endif
    % if 'containerRegistryBase' in values['global']:
    image:
      registry: ${values['global']['containerRegistryBase']}
    % endif     
    % if 'containerRegistryBase' in values['global']:
    cleaner:
      image:
        registry: ${values['global']['containerRegistryBase']}
    % endif
    serviceAccount:
      create: false
      name: "platform"
    # -- Configuration for underlying cass-operator helm-chart. See https://github.com/k8ssandra/k8ssandra/tree/main/charts/cass-operator
    cass-operator:
      % if 'containerRegistryBase' in values['global']:
      image:      
        registry: ${values['global']['containerRegistryBase']}
      % endif
      admissionWebhooks:
        enabled: false
      serviceAccount:
        create: false
        name: "platform"
    # -- CRD Upgrader is disabled by default as we manage CRDs ourselves
    disableCrdUpgraderJob: true
  # -- If true, will create DbConnection and DbRoles. See [cassandra-vault](templates/cassandra-vault.yaml)
  vaultConfiguration: true
  # -- Name of the cassandra cluster used as a backend for main-cassandra-service. See [main-service](templates/main-service.yaml)
  mainCassandraCluster: "cluster"
  clusters:
    cluster:
      enabled: true
      # -- Cassandra cluster spec section
      spec:
        cassandra:
          serviceAccount: platform
          serverVersion: "3.11.13"
          # -- Setting serverImage to override the value coming from k8ssandra-operator.global.imageconfig.types
          serverImage: "${values['global']['containerRegistryBase']}/k8ssandra/cass-management-api:3.11.13"
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
                  storage: 20Gi
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
              % if 'containerRegistryBase' in values['global']:              
              perNodeConfigInitContainerImage: ${values['global']['containerRegistryBase']}/platform/platform-k8s-tools-minimal:1.3.2_202508131123_master_e140ddde
              % else:
              perNodeConfigInitContainerImage: platform.artifactory.qvantel.net/platform/platform-k8s-tools-minimal:1.3.2_202508131123_master_e140ddde
              % endif
              racks:
                - name: default
                  % if values['global']['platformMasters']:
                  nodeAffinityLabels:
                    ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
                  % endif
              tolerations:
                - effect: NoSchedule
                  key: "${values['global']['platformMastersKey']}"
                  operator: Equal
                  value: "${values['global']['platformMastersValue']}"
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
                release: ${values['global']['helmReleaseNamePrefix']}monitoring-platform
            mcac:
              enabled: false
        reaper:
          autoScheduling:
            enabled: true
