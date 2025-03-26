minioPlatform:
  minio:
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/minio/minio
      tag: RELEASE.2024-12-18T13-15-44Z
      % endif
    mcImage:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/minio/mc
      tag: RELEASE.2024-11-21T17-21-54Z
      % endif

    mode: distributed

    ignoreChartChecksums: true

    minioAPIPort: "9000"
    minioConsolePort: "9001"

    existingSecret: "platform-minio-root"

    # Number of drives attached to a node
    drivesPerNode: 1
    # Number of MinIO containers running
    replicas: 4
    # Number of expanded MinIO clusters
    pools: 1

    persistence:
      enabled: true
      storageClass: ""
      volumeName: ""
      accessMode: ReadWriteOnce
      size: 10Gi

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

    securityContext:
      enabled: false

    resources:
      requests:
        memory: 1Gi

    ## List of users to be created after minio install
    ##
    users:
      - accessKey: platform-minio-readwrite
        existingSecret: platform-minio-readwrite
        existingSecretKey: readwritePassword
        policy: readwrite

    ## List of buckets to be created after minio install
    ##
    buckets:
      - name: cassandra-backup
      - name: loki-logs
      - name: postgres-backup
      - name: mariadb-backup