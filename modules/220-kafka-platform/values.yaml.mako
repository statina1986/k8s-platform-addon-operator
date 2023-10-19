kafkaPlatform:
  strimziHelmVersion: "0.37.0"
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
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
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
            default.replication.factor: 3            
            log.retention.hours: 168
            num.partitions: 3
            offsets.topic.replication.factor: 3
            transaction.state.log.min.isr: 2
            transaction.state.log.replication.factor: 3
            min.insync.replicas: 2
            group.initial.rebalance.delay.ms: 3000
            % if values['global']['configurationProfile'] in {'perf', 'prod'}:
            num.partitions: 12            
            transaction.state.log.num.partitions: 48
            offsets.topic.num.partitions: 48
            delete.topic.enable: true
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
            size: 100Gi
            deleteClaim: false
          metricsConfig:
            type: jmxPrometheusExporter
            valueFrom:
              configMapKeyRef:
                name: kafka-metrics
                key: kafka-metrics-config.yml
          rack:
            topologyKey: topology.kubernetes.io/zone
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
                % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                      - matchExpressions:
                        - key: dedicated-nodes
                          operator: In
                          values:
                          - platform-masters
                % endif
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      strimzi.io/cluster: kafka-cluster
                      strimzi.io/name: kafka-cluster-kafka
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
            size: 100Gi
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
                % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                      - matchExpressions:
                        - key: dedicated-nodes
                          operator: In
                          values:
                          - platform-masters
                % endif
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      strimzi.io/cluster: kafka-cluster
                      strimzi.io/name: kafka-cluster-zookeeper
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
              % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
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
              % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
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
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      strimzi.io/cluster: kafka-cluster
                      strimzi.io/name: kafka-cluster-zookeeper
          topicRegex: ".*"
          groupRegex: ".*"
