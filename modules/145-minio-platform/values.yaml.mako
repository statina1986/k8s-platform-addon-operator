minioPlatform:
  minio:
    # -- MinIO image version
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/minio/minio
      tag: RELEASE.2024-12-18T13-15-44Z
      % endif
    # -- MinIO console image version
    mcImage:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/minio/mc
      tag: RELEASE.2024-11-21T17-21-54Z
      % endif

    # -- MinIO mode, i.e. standalone or distributed
    % if values['global']['configurationProfile'] in {'dev'}:
    mode: standalone
    % else:
    mode: distributed
    % endif

    # -- Ignore changing config checksums, to avoid unnecessary restarts
    ignoreChartChecksums: true

    minioAPIPort: "9000"
    minioConsolePort: "9001"

    # -- Use existing Secret for root user
    existingSecret: "platform-minio-root"

    # -- Number of drives attached to a node
    drivesPerNode: 1

    # -- Number of MinIO containers to deploy
    % if values['global']['configurationProfile'] in {'dev'}:
    replicas: 1
    % else:
    replicas: 3
    % endif

    # -- Number of expanded MinIO clusters
    pools: 1

    # -- MinIO persistent volumes configuration
    persistence:
      enabled: true
      storageClass: ""
      volumeName: ""
      accessMode: ReadWriteOnce
      size: 30Gi

    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['multiZone']['enabled']:
    topologySpreadConstraints:
      - labelSelector:
          matchLabels:
            app: minio
        maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
    % endif

    # -- Enable stateful containers to have security context
    securityContext:
      enabled: false

    # -- Resource settings for MinIO pods
    resources:
      requests:
        memory: 1Gi
    # -- List of users and their credentials to be created after MinIO install
    users:
      - accessKey: platform-minio-readwrite
        existingSecret: platform-minio-readwrite
        existingSecretKey: readwritePassword
        policy: readwrite

    # -- List of buckets to be created after MinIO install
    buckets:
      - name: cassandra-backup
      - name: loki-logs
      - name: postgres-backup
      - name: mariadb-backup

    # -- Environment variables to add to the MinIO pods
    # @default -- see child items docs
    environment:
      # -- Enables advanced metrics in MinIO Console if monitoring-platform module is enabled
      % if addon_operator['monitoringPlatformEnabled'] == 'true':
      MINIO_PROMETHEUS_URL: "http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-prometheus.${values['global']['platformNamespace']}.svc.cluster.local:9090"
      % endif
