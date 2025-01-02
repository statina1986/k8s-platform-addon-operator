elasticsearchPlatform:
  % if 'containerRegistryBase' in values['global']:
  loggingSetupimage: ${values['global']['containerRegistryBase']}/platform/platform-k8s-tools-minimal:1.2.0_10_5193dbce5
  % else:
  loggingSetupimage: platform.artifactory.qvantel.net/platform/platform-k8s-tools-minimal:1.2.0_10_5193dbce5
  % endif
  eck-operator:
    % if values['global']['deployOperators'] == "false":
    enabled: false
    % else:
    enabled: true
    % endif
    # Leave this false so that the CRDs in the resources folder are used.
    installCRDs: false
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/elastic/eck-operator
      % endif
    nameOverride: "elastic-operator"
    fullnameOverride: "elastic-operator"
    managedNamespaces: []
    % if values['global']['clusterwideResources'] == "false":
    createClusterScopedResources: false
    webhook:
      enabled: false
    config:
      validateStorageClass: false
    % endif
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
  logstashEnabled: false
  filebeatEnabled: false
  smartsearch:
    enabled: true
  kibana:
    enabled: true
  # Prod is used for 30d log retention, logsearchTestEnv for 2d log retention and logsearchBackup is used to configure ELK-stack to use S3 storage
  prod:
    enabled: false
  windprodlogging:
    enabled: false
  logsearchTestEnv:
    enabled: false

  clusters:
    logsearch:
      % if values['global']['deployOperators'] == "false":
      enabled: false
      % else:
      enabled: true
      % endif
      storageSize: "50Gi"
      resources:
        limits:
          memory: 4000Mi
          cpu: "1"
        requests:
          memory: 1000Mi
          cpu: "0.1"
      spec: |
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
                    storage: {{ .Values.elasticsearchPlatform.clusters.logsearch.storageSize}}
          podTemplate:
            spec:
              containers:
                - name: elasticsearch
                  % if 'containerRegistryBase' in values['global']:
                  image: ${values['global']['containerRegistryBase']}/library/elasticsearch:7.16.2
                  % endif
                  resources: {{ toYaml .Values.elasticsearchPlatform.clusters.logsearch.resources | nindent 12  }}                    
                  env:
                  - name: ZONE
                    valueFrom:
                      fieldRef:
                        fieldPath: metadata.annotations['topology.kubernetes.io/zone']
              tolerations:
                - key: "${values['global']['platformMastersKey']}"
                  value: "${values['global']['platformMastersValue']}"
                  operator: "Equal"
                  effect: "NoSchedule"
              % if values['global']['platformMasters']:
              nodeSelector:
                ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
              % endif
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      elasticsearch.k8s.elastic.co/cluster-name: logsearch
                      elasticsearch.k8s.elastic.co/statefulset-name: logsearch-es-logsearch
    smartsearch:
      % if values['global']['deployOperators'] == "false":
      enabled: false
      % else:
      enabled: true
      % endif
      storageSize: "10Gi"
      resources:
        requests:
          memory: 1Gi
          cpu: 0.1
        limits:
          memory: 2Gi
          cpu: 1
      spec: |
        version: 7.16.2
        volumeClaimDeletePolicy: DeleteOnScaledownOnly
        http:
          tls:
            selfSignedCertificate:
              disabled: true
        nodeSets:
        - name: smartsearch
          count: 1
          config:
            node.master: true
            node.data: true
            node.ingest: true
            node.store.allow_mmap: false    
            xpack.security.authc:
              anonymous:
                authz_exception: false
                roles: superuser
                username: anonymous
          volumeClaimTemplates:
              - metadata:
                  name: elasticsearch-data
                spec:
                  accessModes:
                    - ReadWriteOnce
                  resources:
                    requests:
                      storage: {{ .Values.elasticsearchPlatform.clusters.smartsearch.storageSize }}
          podTemplate:
            spec:
              tolerations:
                - key: "${values['global']['platformMastersKey']}"
                  value: "${values['global']['platformMastersValue']}"
                  operator: "Equal"
                  effect: "NoSchedule"
              % if values['global']['platformMasters']:
              nodeSelector:
                ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
              % endif
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      elasticsearch.k8s.elastic.co/cluster-name: smartsearch
                      elasticsearch.k8s.elastic.co/statefulset-name: smartsearch-es-smartsearch
              containers:
                - name: elasticsearch
                  % if 'containerRegistryBase' in values['global']:
                  image: ${values['global']['containerRegistryBase']}/library/elasticsearch:7.16.2
                  % endif
                  resources: {{ toYaml .Values.elasticsearchPlatform.clusters.smartsearch.resources | nindent 12 }}
  kibanas:
    kibana:
      % if values['global']['deployOperators'] == "false":
      enabled: false
      % else:
      enabled: true
      % endif
      resources:
        requests:
          memory: 0.5Gi
          cpu: 0.1
      spec: |
        http:
          tls:
            selfSignedCertificate:
              disabled: true
        version: 7.16.2
        count: 1
        elasticsearchRef:
          name: logsearch
          namespace: ${values['global']['platformNamespace']}
        podTemplate:
          spec:
            containers:
              - name: kibana
                % if 'containerRegistryBase' in values['global']:
                image: ${values['global']['containerRegistryBase']}/library/kibana:7.16.2
                % endif
                resources: {{  toYaml .Values.elasticsearchPlatform.kibanas.kibana.resources  | nindent 10 }}
            tolerations:
              - key: "${values['global']['platformMastersKey']}"
                value: "${values['global']['platformMastersValue']}"
                operator: "Equal"
                effect: "NoSchedule"
            % if values['global']['platformMasters']:
            nodeSelector:
              ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
            % endif
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
    maxUnavailable: {}
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
        if ([kubernetes][namespace] == "${values['global']['appsNamespace']}") {
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
            if ([kubernetes][namespace] == "${values['global']['platformNamespace']}"
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
            else if ([kubernetes][namespace] == "${values['global']['appsNamespace']}") {
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
            else if ([kubernetes][namespace] not in "${values['global']['platformNamespace']}"
                and[kubernetes][namespace] not in "istio-system"
                and[kubernetes][namespace] not in "pomerium"
                and[kubernetes][namespace] not in "${values['global']['appsNamespace']}"
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
        value: logsearch-es-http.${values['global']['platformNamespace']}.svc.cluster.local
      - name: ELASTICSEARCH_PORT
        value: "9200"
    % if 'containerRegistryBase' in values['global']:
    image:  ${values['global']['containerRegistryBase']}/library/logstash
    % endif
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
        value: elasticsearch-platform-logstash.${values['global']['platformNamespace']}.svc.cluster.local
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
            hosts: <%text>['${LOGSTASH_HOST:elasticsearch-platform-logstash.${values['global']['platformNamespace']}.svc.cluster.local}:${LOGSTASH_PORT:5044}']</%text>
            logging.level: info
      resources:
        requests:
          cpu: "100m"
          memory: "200Mi"
        limits:
          cpu: "100"
          memory: 1Gi
      tolerations: []
    % if 'containerRegistryBase' in values['global']:
    image:  ${values['global']['containerRegistryBase']}/library/filebeat
    % endif
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
