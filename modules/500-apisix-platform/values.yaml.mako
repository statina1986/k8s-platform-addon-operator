apisixPlatform:
  apisix:
    dashboard:
      enabled: true
      config:
        conf:
          etcd:
            endpoints:
              - apisix-platform-etcd:2379
