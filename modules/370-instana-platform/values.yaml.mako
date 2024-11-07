instanaPlatform:
  instana-agent:
    enabled: true
    agent:
      image:
        % if 'containerRegistryBase' in values['global']:
        name: ${values['global']['containerRegistryBase']}/agent/static
        tag: 1.276.0
        % endif
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
        % if 'containerRegistryBase' in values['global']:
        name: ${values['global']['containerRegistryBase']}/instana/leader-elector
        % endif
    k8s_sensor:
      image:
        % if 'containerRegistryBase' in values['global']:
        name: ${values['global']['containerRegistryBase']}/instana/k8sensor
        tag: ffb74e9
        % endif