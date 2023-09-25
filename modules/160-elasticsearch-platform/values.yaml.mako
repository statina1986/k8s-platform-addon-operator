elasticsearchPlatform:
  eck-operator:
    # Leave this false so that the CRDs in the resources folder are used.
    installCRDs: false
    image:
      # repository is the container image prefixed by the registry name.
      repository: artifactory.qvantel.net/helm-k8s-eck-operator
      # pullPolicy is the container image pull policy.
      pullPolicy: IfNotPresent
      # tag is the container image tag. If not defined, defaults to chart appVersion.
      tag: 2.2.0
    nameOverride: "elastic-operator"
    fullnameOverride: "elastic-operator"
    managedNamespaces: []
    createClusterScopedResources: true
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes.
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
  logstashEnabled: true
  filebeatEnabled: true
  smartsearch:
    enabled: true
  kibana:
    enabled: true
  logsearch:
    enabled: true
  # Prod is used for 30d log retention, logsearchTestEnv for 2d log retention and logsearchBackup is used to configure ELK-stack to use S3 storage
  prod:
    enabled: false
  logsearchTestEnv:
    enabled: false
  logsearchBackup:
    enabled: false

  configElastic:
    definitions:
      version: 7.16.2
      volumeClaimDeletePolicy: DeleteOnScaledownAndClusterDeletion
      http:
        tls:
          selfSignedCertificate:
            disabled: true
      nodeSets:
      - name: logsearch
        count: 1
        config:
          node.attr.zone: <%text>${ZONE}</%text>
          cluster.routing.allocation.awareness.attributes: k8s_node_name,zone
          node.roles: ["master", "data", "ingest", "data_hot"]
          node.store.allow_mmap: false
          logger.org.elasticsearch: info
        volumeClaimTemplates:
          - metadata:
              name: elasticsearch-data
            spec:
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: 500Gi
        podTemplate:
          spec:
            initContainers:
            - name: sysctl
              securityContext:
                privileged: true
                runAsUser: 0
              command: ['sh', '-c', 'sysctl -w vm.max_map_count=262144']
            containers:
              - name: elasticsearch
                image: "artifactory.qvantel.net/helm-k8s-elasticsearch:7.16.2"
                resources:
                  requests:
                    memory: 2000Mi
                    cpu: "1"
                env:
                - name: ZONE
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.annotations['topology.kubernetes.io/zone']
            tolerations:
              - key: "dedicated-nodes"
                value: "platform-masters"
                operator: "Equal"
                effect: "NoSchedule"              
            % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
            nodeSelector:
              dedicated-nodes: platform-masters
            % endif
            topologySpreadConstraints:
              - maxSkew: 1
                topologyKey: topology.kubernetes.io/zone
                whenUnsatisfiable: DoNotSchedule
                labelSelector:
                  matchLabels:
                    elasticsearch.k8s.elastic.co/cluster-name: logsearch
                    elasticsearch.k8s.elastic.co/statefulset-name: logsearch-es-logsearch
      podDisruptionBudget:
        spec:
          minAvailable: 1
          selector:
            matchLabels:
              elasticsearch.k8s.elastic.co/cluster-name: logsearch

  configElasticBackup:
    definitions:
      version: 7.16.2
      volumeClaimDeletePolicy: DeleteOnScaledownAndClusterDeletion
      http:
        tls:
          selfSignedCertificate:
            disabled: true
      nodeSets:
      - name: logsearch
        count: 3
        config:
          node.attr.zone: <%text>${ZONE}</%text>
          cluster.routing.allocation.awareness.attributes: k8s_node_name,zone
          node.attr.data: warm
          node.attr.type: warm
          node.roles: ["master", "data", "ingest", "data_hot", "data_warm"]
          node.store.allow_mmap: false
          logger.org.elasticsearch: info
        volumeClaimTemplates:
          - metadata:
              name: elasticsearch-data
            spec:
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: 500Gi
        podTemplate:
          spec:
            initContainers:
            - name: sysctl
              securityContext:
                privileged: true
                runAsUser: 0
              command: ['sh', '-c', 'sysctl -w vm.max_map_count=262144']
            - name: install-plugins
              command:
              - sh
              - -c
              - |
                bin/elasticsearch-plugin remove repository-s3
                bin/elasticsearch-plugin install --batch repository-s3
              env:
              - name: ZONE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.annotations['topology.kubernetes.io/zone']
            - name: add-access-keys
              env:
              - name: AWS_ACCESS_KEY_ID
                valueFrom:
                  secretKeyRef:
                    name: elastic-keys
                    key: access-key
              - name: AWS_SECRET_ACCESS_KEY
                valueFrom:
                  secretKeyRef:
                    name: elastic-keys
                    key: secret-key
              - name: ZONE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.annotations['topology.kubernetes.io/zone']
              command:
              - sh
              - -c
              - |
                echo $AWS_ACCESS_KEY_ID | bin/elasticsearch-keystore add --stdin --force s3.client.default.access_key
                echo $AWS_SECRET_ACCESS_KEY | bin/elasticsearch-keystore add --stdin --force s3.client.default.secret_key
            containers:
              - name: elasticsearch
                image: "artifactory.qvantel.net/helm-k8s-elasticsearch:7.16.2"
                resources:
                  requests:
                    memory: 2000Mi
                    cpu: "1"
                env:
                - name: ZONE
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.annotations['topology.kubernetes.io/zone']
            topologySpreadConstraints:
              - maxSkew: 1
                topologyKey: topology.kubernetes.io/zone
                whenUnsatisfiable: DoNotSchedule
                labelSelector:
                  matchLabels:
                    elasticsearch.k8s.elastic.co/cluster-name: logsearch
                    elasticsearch.k8s.elastic.co/statefulset-name: logsearch-es-logsearch
      - name: logsearch-cold
        count: 1
        config:
          node.attr.zone: <%text>${ZONE}</%text>
          cluster.routing.allocation.awareness.attributes: k8s_node_name,zone
          node.attr.data: cold
          node.attr.type: cold
          node.roles: ["data_cold", "data_content"]
          node.store.allow_mmap: false
          logger.org.elasticsearch: info
        volumeClaimTemplates:
          - metadata:
              name: elasticsearch-data
            spec:
              accessModes:
                - ReadWriteOnce
              resources:
                requests:
                  storage: 500Gi
        podTemplate:
          spec:
            initContainers:
            - name: sysctl
              securityContext:
                privileged: true
                runAsUser: 0
              command: ['sh', '-c', 'sysctl -w vm.max_map_count=262144']
            - name: install-plugins
              command:
              - sh
              - -c
              - |
                bin/elasticsearch-plugin remove repository-s3
                bin/elasticsearch-plugin install --batch repository-s3
              env:
              - name: ZONE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.annotations['topology.kubernetes.io/zone']
            - name: add-access-keys
              env:
              - name: AWS_ACCESS_KEY_ID
                valueFrom:
                  secretKeyRef:
                    name: elastic-keys
                    key: access-key
              - name: AWS_SECRET_ACCESS_KEY
                valueFrom:
                  secretKeyRef:
                    name: elastic-keys
                    key: secret-key
              - name: ZONE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.annotations['topology.kubernetes.io/zone']
              command:
              - sh
              - -c
              - |
                echo $AWS_ACCESS_KEY_ID | bin/elasticsearch-keystore add --stdin --force s3.client.default.access_key
                echo $AWS_SECRET_ACCESS_KEY | bin/elasticsearch-keystore add --stdin --force s3.client.default.secret_key
            containers:
              - name: elasticsearch
                image: "artifactory.qvantel.net/helm-k8s-elasticsearch:7.16.2"
                resources:
                  requests:
                    memory: 2000Mi
                    cpu: "1"
                env:
                - name: ZONE
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.annotations['topology.kubernetes.io/zone']
            topologySpreadConstraints:
              - maxSkew: 1
                topologyKey: topology.kubernetes.io/zone
                whenUnsatisfiable: DoNotSchedule
                labelSelector:
                  matchLabels:
                    elasticsearch.k8s.elastic.co/cluster-name: logsearch
                    elasticsearch.k8s.elastic.co/statefulset-name: logsearch-es-logsearch
      podDisruptionBudget:
        spec:
          minAvailable: 1
          selector:
            matchLabels:
              elasticsearch.k8s.elastic.co/cluster-name: logsearch

  configKibana:
    definitions:
      http:
        tls:
          selfSignedCertificate:
            disabled: true
      version: 7.16.2
      count: 1
      elasticsearchRef:
        name: logsearch
        namespace: platform
      podTemplate:
        spec:
          containers:
            - name: kibana
              image: "artifactory.qvantel.net/helm-k8s-kibana:7.16.2"
              resources:
                requests:
                  memory: 0.5Gi
                  cpu: 0.1
          % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes.
          nodeSelector:
            dedicated-nodes: platform-masters
          % endif
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
                      - key: kibana.k8s.elastic.co/name
                        operator: In
                        values:
                          - kibana
                  topologyKey: "kubernetes.io/zone"

  logstash:
    replicas: 1
    logstashConfig: 
      logstash.yml: |
        http.host: 0.0.0.0
        xpack.monitoring.elasticsearch.hosts: <%text>["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]</%text>
        xpack.monitoring.elasticsearch.username: 'elastic'
        xpack.monitoring.elasticsearch.password: <%text>'${ELASTICSEARCH_PASSWORD}'</%text>
        pipeline.ecs_compatibility: disabled
      log4j2.properties: |
        logger.logstashpipeline.name = logstash.filters.json
        logger.logstashpipeline.level = INFO
    logstashPipeline:
      logstash.conf: |
        input {
          beats {
            port => 5044
          }
        }
        filter {
        if ([kubernetes][namespace] == "qvantel") {
          json {
            source => "message"
          }
        }
        }
        output {
            if ([message] =~"audit"
                or[message] =~"AUDIT"
                or [log_type] =~ "AUDIT"
                or [message] =~ "(operationType=)|(type=LOG(IN|OUT))"
                or "auditbeat" in [tags]
                or "cassandra" in [tags]
                or "http_error" in [tags]
                or "kerberos" in [tags]
                or "realm" in [tags]
                or "secure" in [tags]
                or "messages" in [tags]
                or "audit" in [tags]) {
                elasticsearch {
                    user => "elastic"
                    password => <%text>"${ELASTICSEARCH_PASSWORD}"</%text>
                    hosts => <%text>["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]</%text>
                    ssl => false
                    ilm_rollover_alias => "auditalias"
                    ilm_pattern => "{now/d}-0001"
                    ilm_policy => "audit_policy"
                }
            }
            if ("tibco" in [tags]
                or "bw" in [tags]
                or "fomplatform" in [tags]
                or "fom" in [tags]
                or "bwplatform" in [tags]
                or "ems" in [tags]) {
                elasticsearch {
                    user => "elastic"
                    password => <%text>"${ELASTICSEARCH_PASSWORD}"</%text>
                    hosts => <%text>["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]</%text>
                    ssl => false
                    ilm_rollover_alias => "all-tibco"
                    ilm_pattern => "{now/d}-0001"
                    ilm_policy => "tibco_policy"
                }
            }
            if ([kubernetes][namespace] == "platform"
                or[kubernetes][namespace] == "elastic-system"
                or[kubernetes][namespace] == "kube-system") {
                elasticsearch {
                    user => "elastic"
                    password => <%text>"${ELASTICSEARCH_PASSWORD}"</%text>
                    hosts => <%text>["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]</%text>
                    ssl => false
                    ilm_rollover_alias => "platformalias"
                    ilm_pattern => "{now/d}-0001"
                    ilm_policy => "platform_policy"
                }
            }
            else if ([kubernetes][namespace] == "qvantel") {
                elasticsearch {
                    user => "elastic"
                    password => <%text>"${ELASTICSEARCH_PASSWORD}"</%text>
                    hosts => <%text>["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]</%text>
                    ssl => false
                    ilm_rollover_alias => "applicationalias"
                    ilm_pattern => "{now/d}-0001"
                    ilm_policy => "application_policy"
                }
            }
            else if ([kubernetes][namespace] == "pomerium"
                or[kubernetes][namespace] == "istio-system") {
                elasticsearch {
                    user => "elastic"
                    password => <%text>"${ELASTICSEARCH_PASSWORD}"</%text>
                    hosts => <%text>["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]</%text>
                    ssl => false
                    ilm_rollover_alias => "ingressalias"
                    ilm_pattern => "{now/d}-0001"
                    ilm_policy => "ingress_policy"
                }
            }
            if ("rbs" in [tags]) {
                    elasticsearch {
                    user => "elastic"
                    password => <%text>"${ELASTICSEARCH_PASSWORD}"</%text>
                    hosts => <%text>["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]</%text>
                    ssl => false
                    ilm_rollover_alias => "applicationalias"
                    ilm_pattern => "{now/d}-0001"
                    ilm_policy => "application_policy"
                }
            }
            else if ([kubernetes][namespace] not in "platform"
                and[kubernetes][namespace] not in "istio-system"
                and[kubernetes][namespace] not in "pomerium"
                and[kubernetes][namespace] not in "qvantel"
                and[kubernetes][namespace] not in "kube-system"
                and[kubernetes][namespace] not in "elastic-system"
                and[message] !~"audit"
                and[message] !~"AUDIT"
                and[message] !~ "(operationType=)|(type=LOG(IN|OUT))") {
                elasticsearch {
                    user => "elastic"
                    password => <%text>"${ELASTICSEARCH_PASSWORD}"</%text>
                    hosts => <%text>["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]</%text>
                    ssl => false
                    ilm_rollover_alias => "undecidedalias"
                    ilm_pattern => "{now/d}-0001"
                    ilm_policy => "undecided_policy"
                }
            }
        }
    extraEnvs:
    #  - name: "ELASTICSEARCH_USERNAME"
    #    valueFrom:
    #      secretKeyRef:
    #        name: elasticsearch-elastic-es-elastic-user
    #        key: elastic
      - name: ELASTICSEARCH_PASSWORD
        valueFrom:
          secretKeyRef:
            name: logsearch-es-elastic-user
            key: elastic
      - name: ELASTICSEARCH_HOST
        value: logsearch-es-http.platform.svc.cluster.local
      - name: ELASTICSEARCH_PORT
        value: "9200"
    image: "artifactory.qvantel.net/helm-k8s-logstash"
    imageTag: "7.16.2"
    imagePullPolicy: "IfNotPresent"
    logstashJavaOpts: "-Xmx1g -Xms1g"
    resources:
      requests:
        cpu: "1"
        memory: 2Gi
      limits:
        cpu: "100"
        memory: 4Gi
    httpPort: 9600
    volumeClaimTemplate:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
    rbac:
      create: true
      serviceAccountName: elasticsearch-platform-logstash
    persistence:
      enabled: true
    extraPorts:
      - name: beats
        containerPort: 5044
        protocol: TCP
    service:
      type: ClusterIP
      ports:
        - name: beats
          port: 5044
          protocol: TCP
          targetPort: 5044
  filebeat: 
    daemonset:
      # additionals labels
      labels:
        k8s-app: filebeat
      # Include the daemonset
      enabled: true
      # - configMapRef:
      #     name: config-secret
      extraEnvs:
      - name: LOGSTASH_HOST
        value: elasticsearch-platform-logstash.platform.svc.cluster.local
      - name: LOGSTASH_PORT
        value: "5044"
      hostNetworking: true
      # Allows you to add any config files in /usr/share/filebeat
      # such as filebeat.yml for daemonset
      filebeatConfig:
        filebeat.yml: |
          filebeat.inputs:
          - type: container
            paths:
              - /var/log/containers/*.log
            processors:
              - add_kubernetes_metadata:
                  host: <%text>${NODE_NAME}</%text>
                  matchers:
                  - logs_path:
                      logs_path: "/var/log/containers/"

          processors:
            - add_cloud_metadata:
            - add_host_metadata:
          output.logstash:
            loadbalance: false
            bulk_max_size: 1024
            hosts: <%text>['${LOGSTASH_HOST:elasticsearch-platform-logstash.platform.svc.cluster.local}:${LOGSTASH_PORT:5044}']</%text>
            logging.level: info
      resources:
        requests:
          cpu: "100m"
          memory: "200Mi"
        limits:
          cpu: "100"
          memory: 1Gi
      tolerations: []
    image: "artifactory.qvantel.net/helm-k8s-filebeat"
    imageTag: "7.16.2"
    imagePullPolicy: "IfNotPresent"
    imagePullSecrets: []
    livenessProbe:
      exec:
        command:
          - sh
          - -c
          - |
            #!/usr/bin/env bash -e
            curl --fail 127.0.0.1:5066
      failureThreshold: 3
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
    readinessProbe:
      exec:
        command:
          - sh
          - -c
          - |
            #!/usr/bin/env bash -e
            filebeat test output
      failureThreshold: 3
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
    # Whether this chart should self-manage its service account, role, and associated role binding.
    managedServiceAccount: true
    # Custom service account override that the pod will use
    serviceAccount: "filebeat"
