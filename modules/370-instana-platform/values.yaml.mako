instanaPlatform:
  instana-agent:
    enabled: true
    agent:
      image:
        name: ${values['instanaPlatform']['instana-agent']['agent']['image']['registry']}/${values['instanaPlatform']['instana-agent']['agent']['image']['repository']}
      keysSecret: instana-agent-key
      endpointHost: ingress-green-saas.instana.io
      endpointPort: 443
      env:
        INSTANA_AGENT_MODE: to-be-set
        INSTANA_AGENT_TAGS: to-be-set
      pod:
        requests:
          cpu: 0.5
          memory: 512
        limits:
          memory: 768
      configuration_yaml: |
        com.instana.plugin.profiling.java:
          enabled: true
        com.instana.plugin.opentelemetry:
          grpc:
            enabled: true
          http:
            enabled: true
        com.instana.ignore:
          processes:
            - 'stunnel'
          arguments:
            - 'io.strimzi.operator.cluster.Main'
            - 'kafka.Kafka'
            - 'org.apache.zookeeper.server.quorum.QuorumPeerMain'
            - 'io.strimzi.operator.topic.Main'
            - 'io.strimzi.operator.user.Main'
    opentelemetry:
      grpc:
        enabled: true
      http:
        enabled: true
    cluster:
      name: to-be-set
    zone:
      name: to-be-set
    leaderElector:
      image:
        name: ${values['instanaPlatform']['instana-agent']['leaderElector']['image']['registry']}/${values['instanaPlatform']['instana-agent']['leaderElector']['image']['repository']}
    k8s_sensor:
      image:
        name: ${values['instanaPlatform']['instana-agent']['k8s_sensor']['image']['registry']}/${values['instanaPlatform']['instana-agent']['k8s_sensor']['image']['repository']}