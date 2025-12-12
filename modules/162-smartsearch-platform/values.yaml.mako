smartsearchPlatform:
  elasticsearch:
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % else:
      registry: docker.io
      % endif
      repository: bitnamilegacy/elasticsearch
      tag: 8.17.1-debian-12-r2
    volumePermissions:
      enabled: true
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc
    metrics:
      enabled: false
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: docker.io
        % endif
        repository: bitnamilegacy/elasticsearch-exporter
        tag: 1.8.0-debian-12-r9
    sysctlImage:
      enabled: false
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % else:
      registry: platform.artifactory.qvantel.net
      % endif
      repository: platform/platform-k8s-tools
      tag: 1.3.3_202509080945_master_90384dcc
    global:
      % if 'containerRegistryBase' in values['global']:
      imageRegistry: ${values['global']['containerRegistryBase']}
      % endif
      security:
        allowInsecureImages: true
    fullnameOverride: "${values['global']['helmReleaseNamePrefix']}smartsearch-platform"
    security:
    # Enabling this also enables copy-tls-certificates init container which does not get
    # templated correctly - it is hard coded to pull bitnami/os-shell and only respects
    # global.imageRegistry value - if you need this, use a custom registry and ensure
    # it has bitnami/os-shell.
      enabled: false
      existingSecret: "smartsearch-elastic"
      tls:
        restEncryption: false
    master:
      masterOnly: false
      replicaCount: 1
      pdb:
        create: false
      resources:
        requests:
          cpu: 0.1
          memory: 1000Mi
        limits:
          cpu: 1
          memory: 2000Mi
      networkPolicy:
        enabled: false
      persistence:
        size: 10Gi
      persistentVolumeClaimRetentionPolicy:
        enabled: true
        whenScaled: Retain
        whenDeleted: Retain   
      serviceAccount:
        create: false
        name: "platform"
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
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app.kubernetes.io/component: master
              app.kubernetes.io/instance: ${values['global']['helmReleaseNamePrefix']}smartsearch-platform
      % endif
    data:
      replicaCount: 0
      pdb:
        create: false
      resources:
        requests:
          cpu: 0.1
          memory: 1000Mi
        limits:
          cpu: 1
          memory: 2000Mi
      networkPolicy:
        enabled: false
      persistence:
        size: 10Gi
      persistentVolumeClaimRetentionPolicy:
        enabled: true
        whenScaled: Retain
        whenDeleted: Retain
      serviceAccount:
        create: false
        name: "platform"
    coordinating:
      replicaCount: 0
      pdb:
        create: false
      resources:
        requests:
          cpu: 0.1
          memory: 1000Mi
        limits:
          cpu: 1
          memory: 2000Mi
      networkPolicy:
        enabled: false
    ingest:
      enabled: false
      replicaCount: 0
      pdb:
        create: false
      resources:
        requests:
          cpu: 0.1
          memory: 1000Mi
        limits:
          cpu: 1
          memory: 2000Mi
      networkPolicy:
        enabled: false
      serviceAccount:
        create: false
        name: "platform"
    sysctlImage:
      enabled: false
    copyTlsCerts:
      resourcesPreset: "nano"