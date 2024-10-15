redisPlatform:
  redis:
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % endif
    volumePermissions:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
    sysctl:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.2.0_10_5193dbce5
    kubectl:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.2.0_10_5193dbce5
    architecture: replication
    auth:
      enabled: true
      sentinel: true
    commonConfiguration: |-
      # Enable AOF https://redis.io/topics/persistence#append-only-file
      appendonly no
      # Enable RDB persistence, AOF persistence already enabled.
      save 900 1
      save 300 10
      save 60 10000
    master:
      resources:
        limits: {}
        requests: {}
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
      % endif
      persistence:
        enabled: true
        storageClass: ""
        size: 8Gi
    replica:
      replicaCount: 3
      resources:
        limits: {}
        requests: {}
      % if values['global']['platformMasters']:
      nodeSelector:
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
      % endif
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      persistence:
        enabled: true
        storageClass: ""
        size: 8Gi
    sentinel:      
      enabled: true
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
      masterSet: redis
      quorum: 2
      resources:
        limits: {}
        requests: {}
      service:
        annotations:
          consul.hashicorp.com/service-port: tcp-sentinel
    metrics:
      enabled: true
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
