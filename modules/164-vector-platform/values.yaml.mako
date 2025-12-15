vectorPlatform:
  # -- Vector Agent configuration
  agent:
    % if 'containerRegistryBase' in values['global']:
    image:      
      repository: ${values['global']['containerRegistryBase']}/timberio/vector
    % endif
    role: "Agent"
    % if values['global']['deployOperators'] == "true":
    enabled: true
    % else:
    enabled: false
    % endif
    % if values['global']['clusterwideResources'] == "false":
    rbac:
      create: false
    % endif
    serviceAccount:
      create: false
      name: "platform"
    tolerations:
        - operator: Exists    
    customConfig:
      data_dir: /vector-data-dir
      api:
        enabled: true
        address: 0.0.0.0:8686
        playground: false
      sources:
        kubernetes:
          type: kubernetes_logs
        vector_logs:
          type: internal_logs
        vector_metrics:
          type: internal_metrics
      transforms:
        kubernetes_logs_transform:
          type: remap
          inputs:
            - kubernetes
          source: |
            .log_source = "kubernetes_logs"      
            if exists(.kubernetes.namespace_labels) {
              del(.kubernetes.namespace_labels)
            }
        vector_logs_transform:
          type: remap
          inputs:
            - vector_logs
          source: |
            .log_source = "vector_logs"
        vector_metrics_transform:
          type: remap
          inputs: 
          - vector_metrics
          source: |
            del(.tags.file)
      sinks:
        prometheus:
          type: prometheus_exporter
          address: 0.0.0.0:9598
          inputs:
            - vector_metrics_transform
        vector:
          type: vector
          inputs:
            - kubernetes_logs_transform
            - vector_logs_transform
          address: ${values['global']['helmReleaseNamePrefix']}vector-platform-aggregator.${values['global']['platformNamespace']}.svc:6000
  # -- Fluent Bit configuration
  fluent-bit-events-collector:
    % if values['global']['deployOperators'] == "true":
    enabled: true
    % else:
    enabled: false
    % endif
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/fluent/fluent-bit
      % endif
      # Hard coding the tag to override helm chart's 4.0.7 to avoid JSON regression
      # https://fluentbit.io/announcements/v4.0.8/
      tag: 4.0.8
    kind: Deployment
    nameOverride: fluent-bit-events-collector
    testFramework:
      enabled: false
    rbac:
      % if values['global']['clusterwideResources'] == "false":
      create: false
      % else:
      create: true
      % endif
      eventsAccess: true
    serviceAccount:
      create: false
      name: "platform"
    config:
        inputs: |
          [INPUT]
              name kubernetes_events
              tag k8s_events
              # ask k8s API for updates every 30 seconds (default 5)
              interval_sec 30
        outputs: |
          [OUTPUT]
              name forward
              match k8s_events
              host ${values['global']['helmReleaseNamePrefix']}vector-platform-aggregator.${values['global']['platformNamespace']}.svc
              port 9002
  # -- Vector Aggregator configuration
  aggregator:
    % if 'containerRegistryBase' in values['global']:
    image:
      repository: ${values['global']['containerRegistryBase']}/timberio/vector
    % endif
    % if values['global']['deployOperators'] == "true":
    enabled: true
    % else:
    enabled: false
    % endif
    serviceAccount:
      create: false
      name: "platform"
    role: "Aggregator"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    resources:
      requests:
        cpu: 1
        memory: 2Gi
    storage:
      mode: managedPersistentVolumeClaim
      managedPersistentVolumeClaim:
        # The size to allocate.
        size: 5Gi
    % endif
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if addon_operator['elasticsearchPlatformEnabled'] == 'true':
    env:
      - name: ELASTICSEARCH_PASSWORD
        valueFrom:
          secretKeyRef:
            name: logsearch-es-elastic-user
            key: elastic
    % endif
    % if addon_operator['logsearchPlatformEnabled'] == 'true':
    env:
      - name: ELASTICSEARCH_PASSWORD
        valueFrom:
          secretKeyRef:
            name: logsearch-elastic
            key: elasticsearch-password
    % endif
    % if 'containerRegistryBase' in values['global']:
    haproxy:
      image:
        repository: ${values['global']['containerRegistryBase']}/haproxytech/haproxy-alpine
    % endif
    customConfig:
      api:
        address: 0.0.0.0:8686
        enabled: true
        playground: false
      data_dir: /vector-data-dir
      # -- Data sources for Vector Aggregator
      sources:
        vector:
          type: vector
          address: 0.0.0.0:6000
        logstash:
          type: logstash
          address: 0.0.0.0:9000
        vector_metrics:
          type: internal_metrics
        vector_logs:
          type: internal_logs
        k8s_events_fluent:
          type: fluent
          mode: "tcp"
          address: 0.0.0.0:9002
      transforms:
        k8s_events_transform:
          type: remap
          inputs:
            - k8s_events_fluent
          source: |
            .log_source = "k8s-events"
        vector_logs_transform:
          type: remap
          inputs:
            - vector_logs
          source: |
            .log_source = "vector_logs"
        vector_metrics_transform:
          type: remap
          inputs: 
          - vector_metrics
          source: |
            del(.tags.file)
        # -- Identifies logs based on tags so transformations can target specific log types
        log_types:
          type: route
          inputs:
            - vector
            - logstash
          route:
            qvantel_apps: .kubernetes.pod_namespace == "${values['global']['appsNamespace']}"
            istio_gateway: .kubernetes.pod_annotations."inject.istio.io/templates" == "gateway"
            loki: .kubernetes.pod_labels."app.kubernetes.io/name" == "loki"
            vault: .kubernetes.pod_labels."app.kubernetes.io/name" == "vault"
            tibco: .tags != null && includes(array!(.tags), "tibco")
            rbs: .tags != null && includes(array!(.tags), "rbs")
            nodes_messages: .tags != null && includes(array!(.tags), "messages")
            nodes_container: .tags != null && includes(array!(.tags), "container")
            nodes_secure: .tags != null && includes(array!(.tags), "secure")
        # -- Transformation relying on [Generic Log Format](https://qvantel.atlassian.net/wiki/spaces/PDG/pages/1358727788/Generic+Log+Format) for app logs
        qvantel_apps_transform:
          type: remap
          inputs:
            - log_types.qvantel_apps
          source: |
            .log_source = "qvantel_apps"
            if .message != null && .message != "" {
              structured, err = parse_json(.message)
              if err != null {
                log("Unable to parse Qvantel JSON: " + string!(.message), level: "error")
                .parse_error = err
              } else {
                .qvantel_message = .message
                . = merge!(., structured)
                parsed_timestamp, err = parse_timestamp(.@timestamp,"%+")
                if err != null {                  
                  .parse_error = err
                } else {
                  .timestamp = parsed_timestamp
                }                
              }
            }        
        istio_gateway_transform:
          type: remap
          inputs:
            - log_types.istio_gateway
          source: |
            .log_source = "istio_access_logs"
            structured, err = parse_json(.message)
            if err != null {
              log("Unable to parse Istio Access JSON: " + string!(.message), level: "error")
              .parse_error = err
            } else {
              .log_type = "AUDIT"
              . = merge!(., structured)
              parsed_timestamp, err = parse_timestamp(.start_time,"%+")
              if err != null {                  
                .parse_error = err
              } else {
                .timestamp = parsed_timestamp
              }
            }
        % if addon_operator['elasticsearchPlatformEnabled'] == 'true' or addon_operator['logsearchPlatformEnabled'] == 'true':
        # -- Transformation in case ELK is enabled - forwards access logs from Istio
        istio_to_elk_transform:
          inputs:
          - istio_gateway_transform
          source: |
            if exists(.kubernetes.pod_labels.app) {
              .app = .kubernetes.pod_labels.app
            }
            del(.kubernetes)
            .@timestamp = del(.timestamp)
          type: remap
        # -- Transformation in case ELK is enabled - only forwards access logs and app logs which aren't DEBUG or TRACE and could be parsed
        qvantel_apps_no_debug:
          type: filter
          inputs:
            - qvantel_apps_transform
          condition: |
            .log_level != "DEBUG" && .log_level != "TRACE" && !exists(.parse_error)
        % endif
        vault_transform:
          type: remap
          inputs:
            - log_types.vault
          source: |
            .log_source = "vault_audit_logs"
            structured, err = parse_json(.message)
            if err != null {
              log("Unable to parse Vault JSON: " + string!(.message), level: "error")
              .parse_error = err
            } else {
              .log_type = "AUDIT"
              . = merge!(., structured)
              parsed_timestamp, err = parse_timestamp(.time,"%+")
              if err != null {                  
                .parse_error = err
              } else {
                .timestamp = parsed_timestamp
              }
            }
        tibco_transform:
          type: remap
          inputs:
            - log_types.tibco
          source: |
            .log_source = "tibco_logs"
        nodes_messages_transform:
          type: remap
          inputs:
            - log_types.nodes_messages
          source: |
            .log_source = "nodes_messages"
        nodes_container_transform:
          type: remap
          inputs:
            - log_types.nodes_container
          source: |
            .log_source = "nodes_containers"
        nodes_secure_transform:
          type: remap
          inputs:
            - log_types.nodes_secure
          source: |
            .log_source = "nodes_secure"
        rbs_transform:
          type: remap
          inputs:
            - log_types.rbs
          source: |
            .log_source = "rbs_logs"
        # -- Rearranges k8s related labels and discards ones which aren't needed
        cleanup_transform:
          type: remap
          inputs:
            - log_types._unmatched
            - qvantel_apps_transform
            - istio_gateway_transform
            - vault_transform
            - tibco_transform
            - rbs_transform
            - nodes_messages_transform
            - nodes_container_transform
            - nodes_secure_transform
            - vector_logs_transform
            - k8s_events_transform
          source: |
            if exists(.kubernetes.namespace_labels) {
              del(.kubernetes.namespace_labels)
            }
            if exists(.kubernetes.pod_labels.app) {
              .kubernetes.pod_labels_app = .kubernetes.pod_labels.app
            }
            if exists(.kubernetes.pod_labels."app.kubernetes.io/instance") {
              .kubernetes.pod_labels_instance = .kubernetes.pod_labels."app.kubernetes.io/instance"
            }
            if exists(.kubernetes.pod_labels."app.kubernetes.io/name") {
              .kubernetes.pod_labels_name = .kubernetes.pod_labels."app.kubernetes.io/name"
            }
            if exists(.kubernetes.pod_labels."app.kubernetes.io/component") {
              .kubernetes.pod_labels_component = .kubernetes.pod_labels."app.kubernetes.io/component"
            }
            if exists(.kubernetes.pod_labels) {
              del(.kubernetes.pod_labels)
            }
            if exists(.kubernetes.node_labels) {
              del(.kubernetes.node_labels)
            }
            if exists(.kubernetes.pod_annotations) {
              del(.kubernetes.pod_annotations)
            }
        # If a field is missing for sink, vector logs an error such as:
        #
        # WARN sink{component_kind="sink" component_id=loki component_type=loki}: vector::internal_events::template: Internal log [Failed to render template for "label_value "{{ kubernetes.pod_labels_instance }}" with label_key "instance"".] has been suppressed 442 times.
        #
        # Template failed drops the event according to Vector docs: https://vector.dev/docs/reference/configuration/template-syntax/
        # But according to this PR, that is not always true, for example loki sink does preserve the event: https://github.com/vectordotdev/vector/pull/17746
        # 
        # OpenShift used a similar solution for their logging: https://github.com/openshift/cluster-logging-operator/pull/2374
        # -- Transformation adding labels which loki sink configuration expects to exist
        populate_missing_tags_transform:
          type: remap
          inputs:
            - cleanup_transform
          source: |
            if !exists(.severity) {
              .severity = ""
            }
            if !exists(.source_type) {
              .source_type = ""
            }
            if !exists(.log_source) {
              .log_source = ""
            }
            if !exists(.kubernetes.pod_namespace) {
              .kubernetes.pod_namespace = ""
            }
            if !exists(.kubernetes.pod_name) {
              .kubernetes.pod_name = ""
            }
            if !exists(.kubernetes.pod_labels_app) {
              .kubernetes.pod_labels_app = ""
            }
            if !exists(.kubernetes.pod_labels_instance) {
              .kubernetes.pod_labels_instance = ""
            }
            if !exists(.kubernetes.pod_labels_name) {
              .kubernetes.pod_labels_name = ""
            }
            if !exists(.kubernetes.pod_labels_component) {
              .kubernetes.pod_labels_component = ""
            }
            if !exists(.log_type) {
              .log_type = ""
            }
            if !exists(.service_name) {
              .service_name = ""
            }
            if !exists(.artifact_id) {
              .artifact_id = ""
            }
            if !exists(.log_level) {
              .log_level = ""
            }
            if !exists(.kubernetes.hostname) {
              .kubernetes.hostname = ""
            }
            if !exists(.kubernetes.pod_node_name) {
              .kubernetes.pod_node_name = ""
            }
      sinks:
        prometheus:
          type: prometheus_exporter
          address: 0.0.0.0:9598
          inputs:
            - vector_metrics_transform
          buffer:
            max_size: 268435488
            when_full: drop_newest
            type: disk
        loki:
          type: loki
          inputs:
            - populate_missing_tags_transform
          % if values['global']['configurationProfile'] == 'dev':
          endpoint: http://loki-platform.${values['global']['platformNamespace']}.svc.cluster.local.:3100
          % else:
          endpoint: http://loki-write.${values['global']['platformNamespace']}.svc.cluster.local.:3100
          % endif
          out_of_order_action: accept
          labels:
            forwarder: vector_aggregator
            severity: |-
              {{ print "{{ severity }}" }}
            source_type: |-
              {{ print "{{ source_type }}" }}
            log_source: |-
              {{ print "{{ log_source }}" }}
            pod_namespace: |-
              {{ print "{{ kubernetes.pod_namespace }}" }}
            pod_name: |-
              {{ print "{{ kubernetes.pod_name }}" }}
            app: |-
              {{ print "{{ kubernetes.pod_labels_app }}" }}
            # we have to keep this line without spaces otherwise bad toYaml behavior (https://github.com/helm/helm/issues/8789) will wrap this line and break template
            instance: |-
              {{ print "{{ kubernetes.pod_labels_instance }}" }}
            # we have to keep this line without spaces otherwise bad toYaml behavior (https://github.com/helm/helm/issues/8789) will wrap this line and break template
            name: |-
              {{ print "{{ kubernetes.pod_labels_name }}" }}
            # we have to keep this line without spaces otherwise bad toYaml behavior (https://github.com/helm/helm/issues/8789) will wrap this line and break template
            component: |-
              {{ print "{{ kubernetes.pod_labels_component }}" }}
            log_type: |-
              {{ print "{{ log_type }}" }}
            service_name: |-
              {{ print "{{ service_name }}" }}
            artifact_id: |-
              {{ print "{{ artifact_id }}" }}
            level: |-
              {{ print "{{ log_level }}" }}
            hostname: |-
              {{ print "{{ kubernetes.hostname }}" }}              
            pod_node_name: |-
              {{ print "{{ kubernetes.pod_node_name }}" }}
          compression: snappy
          encoding:
            codec: json
          buffer:
            max_size: 268435488
            when_full: drop_newest
            type: disk
        # -- Blackhole sink to avoid "has no consumers" warnings
        drop_unwanted:
          type: blackhole
          inputs:
            - log_types.loki
        % if addon_operator['elasticsearchPlatformEnabled'] == 'true':
        elk_tibco:
          compression: none
          endpoints: 
            - "http://logsearch-es-http.${values['global']['platformNamespace']}.svc.cluster.local.:9200"
          inputs:
            - tibco_transform
          type: elasticsearch
          api_version: v7
          tls:
            verify_certificate: false
            verify_hostname: false
          auth:
            strategy: basic
            password: <%text>"${ELASTICSEARCH_PASSWORD}"</%text> ## here we need to escape ${} from mako templates
            user: elastic
          bulk:
            index: "all-tibco-%Y-%m-%d"
          buffer:
            max_size: 268435488
            when_full: drop_newest
            type: disk
        elk_apps:
          compression: none
          endpoints: 
            - "http://logsearch-es-http.${values['global']['platformNamespace']}.svc.cluster.local.:9200"
          inputs:
            - qvantel_apps_no_debug
            - rbs_transform
          type: elasticsearch
          api_version: v7
          tls:
            verify_certificate: false
            verify_hostname: false
          auth:
            strategy: basic
            password: <%text>"${ELASTICSEARCH_PASSWORD}"</%text> ## here we need to escape ${} from mako templates
            user: elastic
          bulk:
            index: "application-%Y-%m-%d"
          buffer:
            max_size: 268435488
            when_full: drop_newest
            type: disk
        elk_ingress:
          compression: none
          endpoints: 
            - "http://logsearch-es-http.${values['global']['platformNamespace']}.svc.cluster.local.:9200"
          inputs:
            - istio_to_elk_transform
          type: elasticsearch
          api_version: v7
          tls:
            verify_certificate: false
            verify_hostname: false
          auth:
            strategy: basic
            password: <%text>"${ELASTICSEARCH_PASSWORD}"</%text> ## here we need to escape ${} from mako templates
            user: elastic
          bulk:
            index: "ingress-%Y-%m-%d"
          buffer:
            max_size: 268435488
            when_full: drop_newest
            type: disk
        % endif
        % if addon_operator['logsearchPlatformEnabled'] == 'true':
        elk_tibco:
          compression: none
          endpoints: 
            - "http://${values['global']['helmReleaseNamePrefix']}logsearch-platform.${values['global']['platformNamespace']}.svc.cluster.local.:9200"
          inputs:
            - tibco_transform
          type: elasticsearch
          tls:
            verify_certificate: false
            verify_hostname: false
          auth:
            strategy: basic
            password: <%text>"${ELASTICSEARCH_PASSWORD}"</%text> ## here we need to escape ${} from mako templates
            user: elastic
          bulk:
            index: "all-tibco-%Y-%m-%d"
          buffer:
            max_size: 268435488
            when_full: drop_newest
            type: disk
        elk_apps:
          compression: none
          endpoints: 
            - "http://${values['global']['helmReleaseNamePrefix']}logsearch-platform.${values['global']['platformNamespace']}.svc.cluster.local.:9200"
          inputs:
            - qvantel_apps_no_debug
            - rbs_transform
          type: elasticsearch
          tls:
            verify_certificate: false
            verify_hostname: false
          auth:
            strategy: basic
            password: <%text>"${ELASTICSEARCH_PASSWORD}"</%text> ## here we need to escape ${} from mako templates
            user: elastic
          bulk:
            index: "application-%Y-%m-%d"
          buffer:
            max_size: 268435488
            when_full: drop_newest
            type: disk
        elk_ingress:
          compression: none
          endpoints: 
            - "http://${values['global']['helmReleaseNamePrefix']}logsearch-platform.${values['global']['platformNamespace']}.svc.cluster.local.:9200"
          inputs:
            - istio_to_elk_transform
          type: elasticsearch
          tls:
            verify_certificate: false
            verify_hostname: false
          auth:
            strategy: basic
            password: <%text>"${ELASTICSEARCH_PASSWORD}"</%text> ## here we need to escape ${} from mako templates
            user: elastic
          bulk:
            index: "ingress-%Y-%m-%d"
          buffer:
            max_size: 268435488
            when_full: drop_newest
            type: disk
        % endif
