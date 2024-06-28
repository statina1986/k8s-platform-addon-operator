consulPlatform:
  global:
    image: ${values['consulPlatform']['images']['consul']['registry']}/${values['consulPlatform']['images']['consul']['repository']}:${values['consulPlatform']['images']['consul']['tag']}
    imageK8S: ${values['consulPlatform']['images']['consul-k8s-control-plane']['registry']}/${values['consulPlatform']['images']['consul-k8s-control-plane']['repository']}:${values['consulPlatform']['images']['consul-k8s-control-plane']['tag']}
    imageConsulDataplane: ${values['consulPlatform']['images']['consul-dataplane']['registry']}/${values['consulPlatform']['images']['consul-dataplane']['repository']}:${values['consulPlatform']['images']['consul-dataplane']['tag']}
  apiGateway:
    imageEnvoy: ${values['consulPlatform']['images']['envoy']['registry']}/${values['consulPlatform']['images']['envoy']['repository']}:${values['consulPlatform']['images']['envoy']['tag']}
  updateCoreDns:    
    enabled: "true"
    configmapName: "coredns"
    configmapNamespace: "kube-system"
  consul:
    server:
      replicas: 3
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
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      topologySpreadConstraints: |
        - labelSelector:
            matchLabels:
              app: {{ template "consul.name" . }}
              release: "{{ .Release.Name }}"
              component: server
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
      nodeSelector: |
        dedicated-nodes: platform-masters
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
