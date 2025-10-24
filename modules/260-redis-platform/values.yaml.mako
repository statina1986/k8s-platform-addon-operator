redisPlatform:
  redis:
    rbac:
        create: true
    serviceAccount:
      create: true
      name: redis 
    global:
      security:
        allowInsecureImages: true
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % else:
      registry: platform.artifactory.qvantel.net
      % endif
      repository: platform/bitnami-redis
      tag: 8.2.2
    volumePermissions:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc
    sysctl:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc
    kubectl:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc
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
      automountServiceAccountToken: true
      % if values['global']['configurationProfile'] in {'dev'}:
      replicaCount: 1
      % else:
      replicaCount: 3
      % endif
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
      masterService:
        enabled: true
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/bitnami-redis-sentinel
        tag: 8.2.2
      masterSet: redis
      % if values['global']['configurationProfile'] in {'dev'}:
      quorum: 1
      % else:
      quorum: 2
      % endif
      resources:
        limits: {}
        requests: {}
      service:
        createMaster: true
        annotations:
          platform.qvantel.com/consul-service-port: "26379"
          consul.hashicorp.com/service-port: tcp-sentinel
    metrics:
      enabled: true
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/bitnami-redis-exporter
        tag: 1.79.0