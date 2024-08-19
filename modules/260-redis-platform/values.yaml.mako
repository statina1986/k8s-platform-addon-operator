redisPlatform:
  redis:
    image:
      registry: ${values['global']['containerRegistryBase']}
    volumePermissions:
      image:
        registry: ${values['global']['containerRegistryBase']}
    sysctl:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: platform/platform-k8s-tools-minimal
        tag: 1.2.0_4_20c54b53f
    kubectl:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: platform/platform-k8s-tools-minimal
        tag: 1.2.0_4_20c54b53f
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
      % if values['global']['platformMasters']:
      nodeSelector:
        dedicated-nodes: platform-masters
      % endif
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
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
        dedicated-nodes: platform-masters
      % endif
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      persistence:
        enabled: true
        storageClass: ""
        size: 8Gi
    sentinel:      
      enabled: true
      image:
        registry: ${values['global']['containerRegistryBase']}
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
        registry: ${values['global']['containerRegistryBase']}
