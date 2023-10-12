vectorPlatform:
  agent:
    role: "Agent"
    enabled: true
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
            - kubernetes
            - vector_logs_transform
          address: vector-platform-aggregator.platform.svc:6000
  aggregator:
    enabled: true
    role: "Aggregator"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    replicas: 3
    nodeSelector:
      dedicated-nodes: platform-masters
    resources:
      requests:
        cpu: 1
        memory: 2Gi
    % endif
    tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
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
    customConfig:
      api:
        address: 0.0.0.0:8686
        enabled: true
        playground: false
      data_dir: /vector-data-dir
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
      transforms:
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
        log_types:
          type: route
          inputs:
            - vector
            - logstash
          route:
            qvantel_apps: .kubernetes.pod_namespace == "qvantel"
            istio_gateway: .kubernetes.pod_annotations."inject.istio.io/templates" == "gateway"
            loki: .kubernetes.pod_labels."app.kubernetes.io/name" == "loki"
            vault: .kubernetes.pod_labels."app.kubernetes.io/name" == "vault"
            tibco: .tags != null && includes(array!(.tags), "tibco")
            rbs: .tags != null && includes(array!(.tags), "rbs")
            nodes_messages: .tags != null && includes(array!(.tags), "messages")
            nodes_container: .tags != null && includes(array!(.tags), "container")
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
                parsed_timestamp, err = to_timestamp(.@timestamp)
                if err != null {
                  parsed_timestamp = parse_timestamp!(.@timestamp, "%Y-%m-%dT%H:%M:%S%.3f%z")
                  .timestamp = parsed_timestamp
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
              .timestamp = to_timestamp!(.start_time)
            }
        % if addon_operator['elasticsearchPlatformEnabled'] == 'true':
        istio_to_elk_transform:
          inputs:
          - istio_gateway_transform
          source: |
            del(.kubernetes)
            .@timestamp = del(.timestamp)
          type: remap
        qvantel_apps_no_debug:
          type: filter
          inputs:
            - qvantel_apps_transform
          condition: |
            .log_level != "DEBUG" && .log_level != "TRACE"
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
              .timestamp = to_timestamp!(.time)
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
        rbs_transform:
          type: remap
          inputs:
            - log_types.rbs
          source: |
            .log_source = "rbs_logs"
      sinks:
        prometheus:
          type: prometheus_exporter
          address: 0.0.0.0:9598
          inputs:
            - vector_metrics_transform
        loki:
          type: loki
          inputs:
            - log_types._unmatched
            - qvantel_apps_transform
            - istio_gateway_transform
            - vault_transform
            - tibco_transform
            - rbs_transform
            - nodes_messages_transform
            - nodes_container_transform
            - vector_logs_transform      
          % if values['global']['configurationProfile'] == 'dev':
          endpoint: http://loki-platform.platform.svc:3100
          % else:
          endpoint: http://loki-write.platform.svc:3100
          % endif
          out_of_order_action: accept
          labels:
            forwarder: vector_aggregator
            source_type: |-
              {{ print "{{ source_type }}" }}
            log_source: |-
              {{ print "{{ log_source }}" }}
            pod_namespace: |-
              {{ print "{{ kubernetes.pod_namespace }}" }}
            pod_name: |-
              {{ print "{{ kubernetes.pod_name }}" }}
            pod_labels_*: |-
              {{ print "{{ kubernetes.pod_labels }}" }}
            log_type: |-
              {{ print "{{ log_type }}" }}
            service_name: |-
              {{ print "{{ service_name }}" }}
            artifact_id: |-
              {{ print "{{ artifact_id }}" }}
            log_level: |-
              {{ print "{{ log_level }}" }}
            level: |-
              {{ print "{{ log_level }}" }}
          compression: snappy
          encoding:
            codec: json
        % if addon_operator['elasticsearchPlatformEnabled'] == 'true':
        elk_tibco:
          compression: none
          endpoint: http://logsearch-es-http.platform.svc:9200
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
        elk_apps:
          compression: none
          endpoint: http://logsearch-es-http.platform.svc:9200
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
        elk_ingress:
          compression: none
          endpoint: http://logsearch-es-http.platform.svc:9200
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
        % endif
