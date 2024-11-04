consulPlatform:
  global:
    % if 'containerRegistryBase' in values['global']:
    image: ${values['global']['containerRegistryBase']}/hashicorp/consul:1.14.4
    imageK8S: ${values['global']['containerRegistryBase']}/hashicorp/consul-k8s-control-plane:1.0.3
    imageConsulDataplane: ${values['global']['containerRegistryBase']}/hashicorp/consul-dataplane:1.0.1
    % endif
    openshift:
      enabled: false
  
  serviceSyncForClusterIP:
    # -- Enables services sync to Consul with ClusterIPs. Instead of 'original' Hashicorp services sync in this case ClusterIPs will be registered in Consul instead of individual pod IPs.
    enabled: "false"
    # -- Purge services in Consul from Hashicorp services sync
    purgeHashicorpConsulSyncServicesOnStartup: "false"
    # -- Purge services in Consul from ClusterIP services sync
    purgeClusterIPConsulSyncServicesOnStartup: "false"
    # -- Schedule for reconciliation. Default is "*/5 * * * *" - so every 5 minutes.
    schedule: "*/5 * * * *"
    # -- Selector for namespaces from which sync services.
    namespaceSelector:
      labelSelector:
        matchLabels:
          "platform.qvantel.com/clusterip-service-consul-sync": "true"      
            
  updateCoreDns:    
    enabled: "true"
    configmapName: "coredns"
    configmapNamespace: "kube-system"
  consul:
    apiGateway:
      % if 'containerRegistryBase' in values['global']:
      imageEnvoy: ${values['global']['containerRegistryBase']}/envoyproxy/envoy:v1.23.1
      % endif
    server:
      % if values['global']['configurationProfile'] in {'dev'}: 
      replicas: 1
      % else:
      replicas: 3
      % endif
      affinity: |
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: {{ template "consul.name" . }}
                  release: "{{ .Release.Name }}"
                  component: server
              topologyKey: kubernetes.io/hostname
      tolerations: |
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"      
      % if values['global']['multiZone']['enabled']:
      topologySpreadConstraints: |
        - labelSelector:
            matchLabels:
              app: {{ template "consul.name" . }}
              release: "{{ .Release.Name }}"
              component: server
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
      % endif
      % if values['global']['platformMasters']:
      nodeSelector: |
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
      % endif
      resources:
        requests:
          memory: "100Mi"
          cpu: "100m"
        limits:
          memory: "1Gi"
          cpu: "100"
      extraConfig: |
        {
          "limits": {
            "http_max_conns_per_client": 2000
          },
          "rpc": {
            "enable_streaming": false
          },
          "telemetry": {
            "disable_hostname": true,
            "prometheus_retention_time": "168h"
          }
        }
    client:
      enabled: false
    syncCatalog:
      enabled: true
      toK8S: false
      k8sPrefix: null
      nodePortSyncType: InternalOnly
      addK8SNamespaceSuffix: false
      resources:
        limits:
          cpu: "100"
          memory: "250Mi"
        requests:
          cpu: "50m"
          memory: "50Mi"
    connectInject:
      enabled: false
      