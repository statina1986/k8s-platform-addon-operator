lokiPlatform:
  loki:
    % if values['global']['deployOperators'] == "false":
    enabled: false
    % else:
    enabled: true
    % endif
    % if values['global']['clusterwideResources'] == "false":
    rbac:
      namespaced: true
    % endif
    memcached:
      % if 'containerRegistryBase' in values['global']:
      image:
        repository: ${values['global']['containerRegistryBase']}/library/memcached
      % endif
    sidecar:
      % if 'containerRegistryBase' in values['global']:
      image:
        repository: ${values['global']['containerRegistryBase']}/kiwigrid/k8s-sidecar
      % endif
      rules:
        label: loki_rule
        labelValue: 'true'
        folder: /rules/fake
        searchNamespace: { $.Release.Namespace }
        resource: configmap
    % if values['global']['configurationProfile'] == 'dev':      
    deploymentMode: SingleBinary
    % else:
    deploymentMode: SimpleScalable
    % endif
    lokiCanary:
      enabled: false
    test:
      enabled: false
    monitoring:
      dashboards:
        enabled: true
        annotations:
          grafana_folder: /tmp/dashboards/Qvantel_platform
      serviceMonitor:
        enabled: true
        labels:
          release: "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
      rules:
        enabled: true
        labels:
          release: "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    loki:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}        
        % endif
        tag: 3.2.0
      analytics:
        reporting_enabled: false
      auth_enabled: false

      commonConfig:
        % if values['global']['configurationProfile'] == 'dev':
        replication_factor: 1
        ring:
          kvstore:
            store: inmemory 
        % endif

      compactor:
        % if values['global']['configurationProfile'] == 'dev':
        delete_request_store: filesystem
        % else:
        delete_request_store: s3
        % endif
        working_directory: /var/loki/compactor
        compaction_interval: 10m
        retention_enabled: true
        retention_delete_delay: 2h
        retention_delete_worker_count: 150

      chunk_store_config:
        max_look_back_period: 672h
        
      limits_config:
        allow_structured_metadata: false
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

      structuredConfig:
        ruler:
          wal:
            dir: /var/loki/ruler-wal
          storage:
            type: local
            local:
              directory: /rules
          rule_path: /rules
          ring:
            kvstore:
              store: inmemory
          external_labels:
            country: need-to-define
            customer: need-to-define
            datacenter: need-to-define
            environment: need-to-define
          alertmanager_url: http://alertmanager.alert.k8s.qvantel.net:9096
          enable_api: true
          enable_alertmanager_v2: true 

      tracing:
        enabled: false

    serviceAccount:
      create: false
      name: platform

    objectStorageSecret:
      create: false
      secretName: ""

    gateway:
      enabled: false
      replicas: 0
    chunksCache:
      enabled: false
      replicas: 0
    resultsCache:
      enabled: false
      replicas: 0
    % if values['global']['configurationProfile'] == 'dev':
    singleBinary:
        replicas: 1
    write:
      replicas: 0
    read:
      replicas: 0
    backend:
      replicas: 0
    % else:
    read:
      replicas: 3
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
      % endif
      % if values['global']['multiZone']['enabled']:
      topologySpreadConstraints:
        - labelSelector:
            matchLabels:
              'app.kubernetes.io/name': loki
              'app.kubernetes.io/component': read
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
      % endif
      extraArgs:        
        - '-config.expand-env=true'        
      extraEnv:
        % if 'objectStorageSecret' in values['lokiPlatform']['loki']:
        - name: OBJECT_STORAGE_USER
          valueFrom:
            secretKeyRef:
              name: ${values['lokiPlatform']['loki']['objectStorageSecret']['secretName']}
              key: OBJECT_STORAGE_USER
        - name: OBJECT_STORAGE_SECRET
          valueFrom:
            secretKeyRef:
              name: ${values['lokiPlatform']['loki']['objectStorageSecret']['secretName']}
              key: OBJECT_STORAGE_SECRET
        % endif   
    write:
      replicas: 3
      persistence:
        size: 50Gi
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
      % endif
      % if values['global']['multiZone']['enabled']:
      topologySpreadConstraints:
        - labelSelector:
            matchLabels:
              'app.kubernetes.io/name': loki
              'app.kubernetes.io/component': write
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
      % endif
      extraArgs:
        - '-config.expand-env=true'        
      extraEnv:
        % if 'objectStorageSecret' in values['lokiPlatform']['loki']:
        - name: OBJECT_STORAGE_USER
          valueFrom:
            secretKeyRef:
              name: ${values['lokiPlatform']['loki']['objectStorageSecret']['secretName']}
              key: OBJECT_STORAGE_USER
        - name: OBJECT_STORAGE_SECRET
          valueFrom:
            secretKeyRef:
              name: ${values['lokiPlatform']['loki']['objectStorageSecret']['secretName']}
              key: OBJECT_STORAGE_SECRET
        % endif  
    backend:
      replicas: 3
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
      % endif
      % if values['global']['multiZone']['enabled']:
      topologySpreadConstraints:
        - labelSelector:
            matchLabels:
              'app.kubernetes.io/name': loki
              'app.kubernetes.io/component': backend
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
      % endif
      extraArgs:        
        - '-config.expand-env=true'        
      extraEnv:
        % if 'objectStorageSecret' in values['lokiPlatform']['loki']:
        - name: OBJECT_STORAGE_USER
          valueFrom:
            secretKeyRef:
              name: ${values['lokiPlatform']['loki']['objectStorageSecret']['secretName']}
              key: OBJECT_STORAGE_USER
        - name: OBJECT_STORAGE_SECRET
          valueFrom:
            secretKeyRef:
              name: ${values['lokiPlatform']['loki']['objectStorageSecret']['secretName']}
              key: OBJECT_STORAGE_SECRET
        % endif       
    % endif
    
  promtail:
    enabled: false