kafkaPlatform:  
  kafka-ui:
    yamlApplicationConfigConfigMap:
      name: "kafbat-ui-configmap"
      keyName: "config.yml"

  # configuration of Strimzi Operator. Values specification: https://github.com/strimzi/strimzi-kafka-operator/blob/main/helm-charts/helm3/strimzi-kafka-operator/values.yaml
  strimzi-kafka-operator:
    resources:
      limits:
        memory: 1Gi
        cpu: "1"
      requests:
        memory: 384Mi
        cpu: 200m
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif

    # Docker images that operator uses to provision various components of Strimzi. 
    kafka:
      image:       
        tagPrefix: ${values['kafkaPlatform']['strimzi-kafka-operator']['kafka']['image']['tag']}
    kafkaConnect:
      image:      
        tagPrefix: ${values['kafkaPlatform']['strimzi-kafka-operator']['kafkaConnect']['image']['tag']}
    tlsSidecarEntityOperator:
      image:
        tagPrefix: ${values['kafkaPlatform']['strimzi-kafka-operator']['tlsSidecarEntityOperator']['image']['tag']}
    kafkaMirrorMaker:
      image:
        tagPrefix: ${values['kafkaPlatform']['strimzi-kafka-operator']['kafkaMirrorMaker']['image']['tag']}
    kafkaExporter:
      image:
        tagPrefix: ${values['kafkaPlatform']['strimzi-kafka-operator']['kafkaExporter']['image']['tag']}
    kafkaMirrorMaker2:
      image:
        tagPrefix: ${values['kafkaPlatform']['strimzi-kafka-operator']['kafkaMirrorMaker2']['image']['tag']}
    cruiseControl:
      image:
        tagPrefix: ${values['kafkaPlatform']['strimzi-kafka-operator']['cruiseControl']['image']['tag']}

  # List of clusters to provision. Spec for each cluster is configured according to "kafka.strimzi.io/v1beta2" resource.
  clusters:
    kafka-cluster:
      enabled: true
      spec:
        kafka:
          version: 3.5.1
          % if values['global']['configurationProfile'] in {'perf', 'prod'}:
          replicas: 6
          % else:
          replicas: 3
          % endif
          config:
            auto.create.topics.enable: "true"
            delete.topic.enable: true
            default.replication.factor: 3            
            log.retention.hours: 168            
            offsets.topic.replication.factor: 3
            transaction.state.log.min.isr: 2
            transaction.state.log.replication.factor: 3
            min.insync.replicas: 2
            group.initial.rebalance.delay.ms: 3000
            compression.type: lz4
            % if values['global']['configurationProfile'] in {'perf', 'prod'}:
            num.partitions: 12            
            transaction.state.log.num.partitions: 48
            offsets.topic.num.partitions: 48                                    
            % else:
            num.partitions: 6
            % endif
          listeners:
            - name: plain
              port: 9092
              type: internal
              tls: false
            - name: tls
              port: 9093
              type: internal
              tls: true
          readinessProbe:
            initialDelaySeconds: 15
            timeoutSeconds: 5
          livenessProbe:
            initialDelaySeconds: 15
            timeoutSeconds: 5
          storage:
            type: persistent-claim
            size: 10Gi
            deleteClaim: false
          metricsConfig:
            type: jmxPrometheusExporter
            valueFrom:
              configMapKeyRef:
                name: kafka-metrics
                key: kafka-metrics-config.yml
          % if values['global']['configurationProfile'] in {'perf', 'prod'}: 
          rack:
            topologyKey: topology.kubernetes.io/zone
          % endif
          template:
            pod:
              tolerations:
                - key: "dedicated-nodes"
                  value: "platform-masters"
                  operator: "Equal"
                  effect: "NoSchedule"
              affinity:
                podAntiAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    - labelSelector:
                        matchExpressions:
                          - key: strimzi.io/cluster
                            operator: In
                            values:
                              - kafka-cluster
                          - key: strimzi.io/name
                            operator: In
                            values:
                              - kafka-cluster-kafka
                      topologyKey: kubernetes.io/hostname
                % if values['global']['platformMasters']:
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                      - matchExpressions:
                        - key: dedicated-nodes
                          operator: In
                          values:
                          - platform-masters
                % endif
              % if values['global']['configurationProfile'] in {'perf', 'prod'}: 
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      strimzi.io/cluster: kafka-cluster
                      strimzi.io/name: kafka-cluster-kafka
              % endif
        zookeeper:
          replicas: 3
          readinessProbe:
            initialDelaySeconds: 15
            timeoutSeconds: 5
          livenessProbe:
            initialDelaySeconds: 15
            timeoutSeconds: 5
          storage:
            type: persistent-claim
            size: 1Gi
            deleteClaim: false
          metricsConfig:
            type: jmxPrometheusExporter
            valueFrom:
              configMapKeyRef:
                name: kafka-metrics
                key: zookeeper-metrics-config.yml
          template:
            pod:
              tolerations:
                - key: "dedicated-nodes"
                  value: "platform-masters"
                  operator: "Equal"
                  effect: "NoSchedule"              
              affinity:
                podAntiAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    - labelSelector:
                        matchExpressions:
                          - key: strimzi.io/cluster
                            operator: In
                            values:
                              - kafka-cluster
                          - key: strimzi.io/name
                            operator: In
                            values:
                              - kafka-cluster-zookeeper
                      topologyKey: kubernetes.io/hostname
                % if values['global']['platformMasters']:
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                      - matchExpressions:
                        - key: dedicated-nodes
                          operator: In
                          values:
                          - platform-masters
                % endif
              % if values['global']['configurationProfile'] in {'perf', 'prod'}: 
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      strimzi.io/cluster: kafka-cluster
                      strimzi.io/name: kafka-cluster-zookeeper
              % endif
        entityOperator:
          topicOperator: {}
          userOperator: {}
          template:
            pod:
              tolerations:
                - key: "dedicated-nodes"
                  value: "platform-masters"
                  operator: "Equal"
                  effect: "NoSchedule"              
              % if values['global']['platformMasters']:
              affinity:                
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                      - matchExpressions:
                        - key: dedicated-nodes
                          operator: In
                          values:
                          - platform-masters
              % endif
        kafkaExporter:
          template:
            pod:
              tolerations:
                - key: "dedicated-nodes"
                  value: "platform-masters"
                  operator: "Equal"
                  effect: "NoSchedule"              
              % if values['global']['platformMasters']:
              affinity:                
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                      - matchExpressions:
                        - key: dedicated-nodes
                          operator: In
                          values:
                          - platform-masters
              % endif
              % if values['global']['configurationProfile'] in {'perf', 'prod'}: 
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      strimzi.io/cluster: kafka-cluster
                      strimzi.io/name: kafka-cluster-zookeeper
              % endif
          topicRegex: ".*"
          groupRegex: ".*"
