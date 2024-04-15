lokiPlatform:
  loki:
    enabled: true
    test:
      enabled: false
    monitoring:
      lokiCanary:
        enabled: false
      selfMonitoring:
        enabled: false
        grafanaAgent:
          installOperator: false
      dashboards:
        annotations:
          k8s-sidecar-target-directory: /tmp/dashboards/Qvantel_platform
      serviceMonitor:
        labels:
          release: monitoring-platform
      rules:
        labels:
          release: monitoring-platform    
    loki:
      analytics:
        reporting_enabled: false
      auth_enabled: false
      structuredConfig:
        ruler:
          storage:
            type: local
            local:
              directory: /var/loki/ruler
      commonConfig:
        % if values['global']['configurationProfile'] == 'dev':
        replication_factor: 1
        ring:
          kvstore:
            store: inmemory 
        % endif

      compactor:
        working_directory: /var/loki/compactor
        % if values['global']['configurationProfile'] == 'dev':
        shared_store: filesystem
        % else:
        shared_store: s3
        % endif
        compaction_interval: 10m
        retention_enabled: true
        retention_delete_delay: 2h
        retention_delete_worker_count: 150

      chunk_store_config:
        max_look_back_period: 672h
        
      limits_config:
        enforce_metric_name: false
        reject_old_samples: true
        reject_old_samples_max_age: "168h"
        max_query_length: "2160h" # 90 days
        max_cache_freshness_per_query: 10m
        split_queries_by_interval: 15m
        ingestion_rate_mb: 100
        ingestion_burst_size_mb: 200
        per_stream_rate_limit: 100MB
        per_stream_rate_limit_burst: 200MB
        retention_period: 744h # 31 days
        retention_stream:
          - selector: '{log_level="DEBUG"}' # keep DEBUG logs only for 2 days
            priority: 1
            period: 48h
          - selector: '{log_level="TRACE"}' # keep TRACE logs only for 2 days
            priority: 1
            period: 48h

      query_scheduler:
        # the TSDB index dispatches many more, but each individually smaller, requests.
        # We increase the pending request queue sizes to compensate.
        max_outstanding_requests_per_tenant: 32768

      querier:
        # Each `querier` component process runs a number of parallel workers to process queries simultaneously.
        # You may want to adjust this up or down depending on your resource usage
        # (more available cpu and memory can tolerate higher values and vice versa),
        # but we find the most success running at around `16` with tsdb
        max_concurrent: 16

      schemaConfig:
        configs:
          - from: "2023-01-01"
            index:
              period: 24h
              prefix: index_
            store: tsdb            
            schema: v12
            % if values['global']['configurationProfile'] == 'dev':
            object_store: filesystem
            % else:
            object_store: s3
            % endif

      server:
        http_server_write_timeout: 310s
        http_server_read_timeout: 310s
        grpc_server_max_recv_msg_size: 104857600  # 100 Mb
        grpc_server_max_send_msg_size: 104857600  # 100 Mb
      
      storage:
        bucketNames:
          chunks: <name-of-your-loki-logs-bucket(s)> ## TO CONFIGURE FOR S3, GCS, etc. Put your logs bucket name here
        s3:             
          s3: s3://<your-S3-region-here> ## TO CONFIGURE FOR S3. Put your S3 connection here, e.g. s3://eu-south-1

        % if values['global']['configurationProfile'] == 'dev':
        type: filesystem
        % else:
        type: s3
        % endif

      storage_config:
        tsdb_shipper:
          % if values['global']['configurationProfile'] == 'dev':
          shared_store: filesystem
          % else:
          shared_store: s3
          % endif
      tracing:
        enabled: false

    serviceAccount:
      create: false
      name: platform

    gateway:
      enabled: false
      replicas: 0

    % if values['global']['configurationProfile'] == 'dev':
    singleBinary:
        replicas: 1
    % else:
    read:
      legacyReadTarget: true
      replicas: 3
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        dedicated-nodes: platform-masters
      % endif
    write:
      replicas: 3
      persistence:
        size: 50Gi
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        dedicated-nodes: platform-masters
      % endif
    % endif
    
  promtail:
    enabled: false
