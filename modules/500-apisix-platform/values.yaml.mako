apisixPlatform:
  apisix:
    serviceMonitor:
      enabled: true
      labels:
        release: monitoring-platform
    dashboard:
      enabled: true
      config:
        conf:
          etcd:
            endpoints:
              - apisix-platform-etcd:2379
