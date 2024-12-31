kafkaPlatform:  
  kafka-ui:
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}      
      % endif
      tag: "126980339425e4bff3d98b020fe606778d3c45b1"
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    yamlApplicationConfigConfigMap:
      name: "kafbat-ui-configmap"
      keyName: "config.yml"
    env:
      - name: JAVA_OPTS
        value: >-
          -Dreactor.netty.pool.maxIdleTime=30000
          -Dreactor.netty.pool.maxLifeTime=60000
      - name: KAFKA_UI_CLIENT_SECRET
        valueFrom:
          secretKeyRef:
            name: kafka-ui-client-secret
            key: KAFKA_UI_CLIENT_SECRET    
    % if values['global']['configurationProfile'] == 'dev':
    authConfig: |
        type: disabled
    rolesConfig: ""
    % else:
    authConfig:
      type: OAUTH2
      oauth2:
        client:
          keycloak:
            clientId: kafbat
            clientSecret: <%text>${KAFKA_UI_CLIENT_SECRET}</%text>
            scope: openid
            client-name: keycloak
            provider: keycloak
            authorization-grant-type: authorization_code
            issuer-uri: https://auth${values['global']['ingressBaseUrlSeparator']}{{ $.Values.global.ingressBaseUrl }}/auth/realms/qvantel
            jwk-set-uri: http://qvaa-proxy-80/auth/realms/qvantel/protocol/openid-connect/certs
            user-name-attribute: preferred_username
            custom-params:
              type: oauth
              roles-field: roles
    rolesConfig: |
      roles: 
        {{- range keys .Values.kafkaPlatform.clusters }}
        {{- $current := get $.Values.kafkaPlatform.clusters . }}
        {{- if $current.enabled }}
        {{- $cluster_name := . }}
        - name: "kafka-admins-{{ $cluster_name }}"
          clusters:
            - {{ $cluster_name }}
          subjects:
            - provider: oauth
              type: role
              value: "kafka-admins"
          permissions:
            - resource: applicationconfig
              actions: all
            - resource: clusterconfig
              actions: all
            - resource: topic
              value: ".*"
              actions: all
            - resource: consumer
              value: ".*"
              actions: all
            - resource: schema
              value: ".*"
              actions: all
            - resource: connect
              value: ".*"
              actions: all
            - resource: ksql
              actions: all
            - resource: acl
              actions: [ view ]
        - name: "kafka-readonly-{{ $cluster_name }}"
          clusters:
            - {{ $cluster_name }}
          subjects:
            - provider: oauth
              type: role
              value: "kafka-readonly"
          permissions:
            - resource: clusterconfig
              actions: [ "view" ]
            - resource: topic
              value: ".*"
              actions: 
                - VIEW
                - MESSAGES_READ
            - resource: consumer
              value: ".*"
              actions: [ view ]
            - resource: schema
              value: ".*"
              actions: [ view ]
            - resource: connect
              value: ".*"
              actions: [ view ]
            - resource: acl
              actions: [ view ]          
        {{- end }}
        {{- end }}
        {{ tpl  (index .Values.kafkaPlatform "kafka-ui" "additionalRoles") . | nindent 8 }}
    % endif
    additionalRoles: ""    

  # configuration of Strimzi Operator. Values specification: https://github.com/strimzi/strimzi-kafka-operator/blob/main/helm-charts/helm3/strimzi-kafka-operator/values.yaml
  strimzi-kafka-operator:
    % if values['global']['clusterwideResources'] == "false":
    rbac:
      create: no
    createGlobalResources: false
    % endif
    % if 'containerRegistryBase' in values['global']:
    defaultImageRegistry: ${values['global']['containerRegistryBase']}
    % endif
    serviceAccountCreate: no
    serviceAccount: platform
    resources:
      limits:
        memory: 1Gi
        cpu: "1"
      requests:
        memory: 384Mi
        cpu: 200m
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    
  # List of clusters to provision. Spec for each cluster is configured according to "kafka.strimzi.io/v1beta2" resource.
  clusters:
    kafka-cluster:
      enabled: true
      spec:
        kafka:
          version: 3.8.0
          % if values['global']['configurationProfile'] in {'dev'}:
          replicas: 1
          % else:
          replicas: 3
          % endif
          
          config:
            auto.create.topics.enable: "true"
            delete.topic.enable: true

            % if values['global']['configurationProfile'] in {'dev'}:
            default.replication.factor: 1
            offsets.topic.replication.factor: 1            
            % else:
            default.replication.factor: 3
            offsets.topic.replication.factor: 3
            transaction.state.log.min.isr: 2
            transaction.state.log.replication.factor: 3
            min.insync.replicas: 2
            % endif

            log.retention.hours: 168                                    
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
                - key: "${values['global']['platformMastersKey']}"
                  value: "${values['global']['platformMastersValue']}"
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
                        - key: ${values['global']['platformMastersKey']}
                          operator: In
                          values:
                          - ${values['global']['platformMastersValue']}
                % endif
              % if values['global']['multiZone']['enabled']:
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
          % if values['global']['configurationProfile'] in {'dev'}:
          replicas: 1
          % else:
          replicas: 3
          % endif
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
                - key: "${values['global']['platformMastersKey']}"
                  value: "${values['global']['platformMastersValue']}"
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
                        - key: ${values['global']['platformMastersKey']}
                          operator: In
                          values:
                          - ${values['global']['platformMastersValue']}
                % endif
              % if values['global']['multiZone']['enabled']:
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
                - key: "${values['global']['platformMastersKey']}"
                  value: "${values['global']['platformMastersValue']}"
                  operator: "Equal"
                  effect: "NoSchedule"              
              % if values['global']['platformMasters']:
              affinity:                
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                      - matchExpressions:
                        - key: ${values['global']['platformMastersKey']}
                          operator: In
                          values:
                          - ${values['global']['platformMastersValue']}
              % endif
        kafkaExporter:
          template:
            pod:
              tolerations:
                - key: "${values['global']['platformMastersKey']}"
                  value: "${values['global']['platformMastersValue']}"
                  operator: "Equal"
                  effect: "NoSchedule"              
              % if values['global']['platformMasters']:
              affinity:                
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                      - matchExpressions:
                        - key: ${values['global']['platformMastersKey']}
                          operator: In
                          values:
                          - ${values['global']['platformMastersValue']}
              % endif
              % if values['global']['multiZone']['enabled']:
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
