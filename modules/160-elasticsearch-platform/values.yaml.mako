elasticsearchPlatform:
  % if 'containerRegistryBase' in values['global']:
  loggingSetupimage: ${values['global']['containerRegistryBase']}/platform/platform-k8s-tools-minimal:1.3.3_202509080945_master_90384dcc
  % else:
  loggingSetupimage: platform.artifactory.qvantel.net/platform/platform-k8s-tools-minimal:1.3.3_202509080945_master_90384dcc
  % endif
  eck-operator:
    % if values['global']['deployOperators'] == "false":
    enabled: false
    % else:
    enabled: true
    % endif
    # Leave this false so that the CRDs in the resources folder are used.
    installCRDs: false
    % if 'containerRegistryBase' in values['global']:
    image:      
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
          memory: 8000Mi
          cpu: "2"
        requests:
          memory: 1000Mi
          cpu: "0.1"
      spec: |
        version: 7.17.29
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
                  image: ${values['global']['containerRegistryBase']}/elasticsearch/elasticsearch:7.17.29
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
              % if values['global']['multiZone']['enabled']:
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      elasticsearch.k8s.elastic.co/cluster-name: logsearch
                      elasticsearch.k8s.elastic.co/statefulset-name: logsearch-es-logsearch
              % endif
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
        version: 7.17.29
        volumeClaimDeletePolicy: DeleteOnScaledownOnly
        http:
          tls:
            selfSignedCertificate:
              disabled: true
        nodeSets:
        - name: smartsearch
          count: 1
          config:
            node.roles: ["master", "data", "ingest", "data_hot"]
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
              % if values['global']['multiZone']['enabled']:
              topologySpreadConstraints:
                - maxSkew: 1
                  topologyKey: topology.kubernetes.io/zone
                  whenUnsatisfiable: DoNotSchedule
                  labelSelector:
                    matchLabels:
                      elasticsearch.k8s.elastic.co/cluster-name: smartsearch
                      elasticsearch.k8s.elastic.co/statefulset-name: smartsearch-es-smartsearch
              % endif
              containers:
                - name: elasticsearch
                  % if 'containerRegistryBase' in values['global']:
                  image: ${values['global']['containerRegistryBase']}/elasticsearch/elasticsearch:7.17.29
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
        version: 7.17.29
        count: 1
        elasticsearchRef:
          name: logsearch
          namespace: ${values['global']['platformNamespace']}
        podTemplate:
          spec:
            containers:
              - name: kibana
                % if 'containerRegistryBase' in values['global']:
                image: ${values['global']['containerRegistryBase']}/kibana/kibana:7.17.29
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
    version: 7.17.3
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
    image:  ${values['global']['containerRegistryBase']}/logstash/logstash
    % endif
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
  eck-beats:
    labels:
      k8s-app: filebeat
    type: filebeat
    version: 7.17.29
    elasticsearchRef: 
      name: ''
    serviceAccount: 
      name: "filebeat"
      namespace: ${values['global']['platformNamespace']}
    config:
      filebeat.inputs:
      - type: filestream
        id: container_logs
        prospector.scanner.symlinks: true
        parsers:
          - container: {}
        paths:
          - "/var/log/containers/*.log"
        processors:
          - add_kubernetes_metadata:
              host: <%text>${NODE_NAME}</%text>
              matchers:
              - logs_path:
                  logs_path: /var/log/containers
          - add_host_metadata: {}
          - add_cloud_metadata: {}
      output.logstash:
        loadbalance: false
        bulk_max_size: 1024
        hosts:
          - "elasticsearch-platform-logstash.${values['global']['platformNamespace']}.svc.cluster.local"
        logging.level: info
    daemonSet:
      podTemplate:
        spec:
          serviceAccount: platform
          automountServiceAccountToken: true
          terminationGracePeriodSeconds: 30
          dnsPolicy: ClusterFirstWithHostNet
          hostNetwork: true # Allows to provide richer host metadata
          containers:
          - name: filebeat
            env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            securityContext:
              runAsUser: 0
              # If using Red Hat OpenShift uncomment this:
              #privileged: true
            volumeMounts:
            - name: varlogcontainers
              mountPath: /var/log/containers
            - name: varlogpods
              mountPath: /var/log/pods
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
          volumes:
          - name: varlogcontainers
            hostPath:
              path: /var/log/containers
          - name: varlogpods
            hostPath:
              path: /var/log/pods
          - name: varlibdockercontainers
            hostPath:
              path: /var/lib/docker/containers