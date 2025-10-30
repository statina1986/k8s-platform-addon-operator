minioPlatform:
  # -- Configuration for underlying minio helm-chart. See https://github.com/minio/minio/tree/master/helm/minio#configuration
  minio:
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/minio/minio      
      % endif
      tag: RELEASE.2025-04-22T22-12-26Z
    mcImage:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/minio/mc     
      % endif
      tag: RELEASE.2025-08-13T08-35-41Z
      
    % if values['global']['configurationProfile'] in {'dev'}:
    mode: standalone
    % else:
    mode: distributed
    % endif

    ignoreChartChecksums: true

    minioAPIPort: "9000"
    minioConsolePort: "9001"

    existingSecret: "platform-minio-root"

    drivesPerNode: 1

    % if values['global']['configurationProfile'] in {'dev'}:
    replicas: 1
    % else:
    replicas: 3
    % endif

    pools: 1

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

    securityContext:
      enabled: false

    resources:
      requests:
        memory: 1Gi
    users:
      - accessKey: platform-minio-readwrite
        existingSecret: platform-minio-readwrite
        existingSecretKey: readwritePassword
        policy: readwrite

    buckets:
      - name: cassandra-backup
      - name: loki-logs
      - name: postgres-backup
      - name: mariadb-backup

    environment:
      # -- Enables advanced metrics in MinIO Console if monitoring-platform module is enabled
      % if addon_operator['monitoringPlatformEnabled'] == 'true':
      MINIO_PROMETHEUS_URL: "http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-prometheus.${values['global']['platformNamespace']}.svc.cluster.local:9090"
      % endif
      # -- Disables login animation, which breaks login page with kubectl port forwarding ( https://github.com/minio/minio/pull/17123 )
      MINIO_BROWSER_LOGIN_ANIMATION: 'off'
