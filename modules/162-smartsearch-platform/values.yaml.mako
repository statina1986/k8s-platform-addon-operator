smartsearchPlatform:
  elasticsearch:
    global:
      % if 'containerRegistryBase' in values['global']:
      imageRegistry: ${values['global']['containerRegistryBase']}
      % endif
      security:
        allowInsecureImages: true
    fullnameOverride: "${values['global']['helmReleaseNamePrefix']}smartsearch-platform"
    security:
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
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app.kubernetes.io/component: master
              app.kubernetes.io/instance: ${values['global']['helmReleaseNamePrefix']}smartsearch-platform
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