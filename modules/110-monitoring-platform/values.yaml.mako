monitoringPlatform:
  qvantelMonitoring:
    #Customer variable to control alerts and dashboards deployed per Program
    programs:  
      mmlyle: false 
      sayco: false
      windtre: false
    #Variable to control applications deployed in the environment
    applications:
      commonOnePointZero: false
      commonZeroPointSix: false
      bssapi: false
      flex: false
      ordersManager: false
    #Modules variables to control alerts and dashboards deployed based on the modules already deployed
    modules:
      kafka: false
      loki: false
      vector: false
      kasope: false
      consul: false
      vault: false
      istio: false
      elasticsearch: false
      postgres: false
      mariadb: false
      redis: false
      rabbitmq: false
      mongo: false
  x509-certificate-exporter:
    enabled: true
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    secretsExporter:
      podExtraLabels:
        "release": "monitoring-platform"
    hostPathsExporter:
      podExtraLabels:
        "release": "monitoring-platform"
    service:
      extraLabels:
        "release": "monitoring-platform"
    prometheusServiceMonitor:
      extraLabels:
        "release": "monitoring-platform"
    prometheusRules:
      extraLabels:
        "release": "monitoring-platform"
  kafka-lag-exporter:
    enabled: true
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
      - name: "kafka-cluster"
        bootstrapBrokers: kafka-cluster-kafka-bootstrap.platform.svc:9092
        groupWhitelist:
          - .*
        topicWhitelist:
          - .*
    prometheus:
      serviceMonitor:
        enabled: true
        additionalLabels:
          "release": "monitoring-platform"
    deploymentExtraLabels:
      "release": "monitoring-platform"
    podExtraLabels:
      "release": "monitoring-platform"
  prometheus-blackbox-exporter:
    enabled: true
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    config:
      modules:
        http_2xx:
          http:
            follow_redirects: true
            preferred_ip_protocol: ip4
            valid_http_versions:
            - HTTP/1.1
            - HTTP/2.0
          prober: http
          timeout: 5s
        http_2xxs_post:
          prober: http
          timeout: 5s
          http:
            valid_status_codes: [200, 403]
            no_follow_redirects: false
            tls_config:
              insecure_skip_verify: true
            method: POST
            preferred_ip_protocol: "ip4"
        http_2xx_json:
          prober: http
          timeout: 5s
          http:
            headers:
              Content-Type: application/json
            body: '{"ResultText": "OK}'
            preferred_ip_protocol: "ip4"    
  yet-another-cloudwatch-exporter:
    enabled: false
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    serviceAccount:
      create: false
      name: platform
    extraArgs:
      scraping-interval: 60
    serviceMonitor:
      enabled: true
      labels:
        "release": "monitoring-platform"
  prometheus-consul-exporter:
    enabled: true
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    consulServer: consul-consul-server:8500
    serviceMonitor:
      labels: 
        "release": "monitoring-platform"
      enabled: true
      interval: 30s
      telemetryPath: /metrics
  kube-prometheus-stack:
    enabled: true
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    defaultRules:
      create: true
      rules:
        kubernetesStorage: false
    grafana:
      enabled: true
      deploymentStrategy:
        type: Recreate
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
      nodeSelector:
        dedicated-nodes: platform-masters
      % endif
      admin:
        existingSecret: grafana-admin-pass-secret
        passwordKey: grafanaAdminPassword
        userKey: adminUser
      serviceMonitor:
        labels:
          "release": "monitoring-platform"
      image:
        # we use enterprise license which is free-to-use to avoid AGPL3 in grafana-oss
        repository: grafana/grafana-enterprise
      persistence:
        type: pvc
        enabled: true
        size: 30Gi
        finalizers:
          - kubernetes.io/pvc-protection
      % if addon_operator['elasticsearchPlatformEnabled'] == 'true':
      envFromSecrets: 
        - name: "logsearch-es-elastic-user"
      % endif
      datasources:
        platform.yaml:
          apiVersion: 1
          datasources:

            - name: Loki
              type: loki
              % if values['global']['configurationProfile'] == 'dev':
              url: http://loki-platform.platform.svc:3100
              % else:
              url: http://loki-read.platform.svc:3100
              % endif
            % if addon_operator['elasticsearchPlatformEnabled'] == 'true':
            - name: Elasticsearch-Ingress
              type: elasticsearch
              access: http
              url: http://logsearch-es-logsearch.service.consul:9200
              basicAuth: true
              basicAuthUser: elastic
              database: ingress*
              isDefault: false
              jsonData:
                timeField: "@timestamp"
              secureJsonData:
                basicAuthPassword: <%text>${elastic}</%text>
            - name: Elasticsearch-Application
              type: elasticsearch
              access: http
              url: http://logsearch-es-logsearch.service.consul:9200
              basicAuth: true
              basicAuthUser: elastic
              database: application*
              isDefault: false
              jsonData:
                timeField: "@timestamp"
              secureJsonData:
                basicAuthPassword: <%text>${elastic}</%text>
            % endif
            
      grafana.ini:
        auth.anonymous:
          enabled: true
          org_role: Viewer
        dataproxy:
          timeout: 310
        server:
          root_url: https://grafana-${values['global']['ingressBaseUrl']}
        users:
          viewers_can_edit: true
        auth.generic_oauth:
          enabled: true
          name: Keycloak-OAuth
          icon: signin
          allow_sign_up: true
          client_id: grafana
          scopes: openid email profile offline_access roles
          email_attribute_path: email
          login_attribute_path: username
          name_attribute_path: full_name
          auth_url: https://auth-${values['global']['ingressBaseUrl']}/auth/realms/qvantel/protocol/openid-connect/auth # override if needed in the target environment values file
          signout_redirect_url: https://auth-${values['global']['ingressBaseUrl']}/auth/realms/qvantel/protocol/openid-connect/logout # override if needed in the target environment values file
          token_url: http://qvaa-proxy-80.qvantel.svc.cluster.local/auth/realms/qvantel/protocol/openid-connect/token
          api_url: http://qvaa-proxy-80.qvantel.svc.cluster.local/auth/realms/qvantel/protocol/openid-connect/userinfo
          role_attribute_path: contains(realm_access.roles[*], 'grafana_admin') && 'Admin' || contains(realm_access.roles[*], 'grafana_server_admin') && 'GrafanaAdmin' || contains(realm_access.roles[*], 'grafana_editor') && 'Editor' || contains(realm_access.roles[*], 'grafana_viewer') && 'Viewer'
          allow_assign_grafana_admin: true
          role_attribute_strict: true
          use_pkce: true
      envFromSecret: grafana-keycloak-client-secret
      sidecar:
        datasources:
          enabled: true
          defaultDatasourceEnabled: true
          maxLines: 1000
        dashboards:
          enabled: true
          label: grafana_dashboard
          labelValue: "1"
          folder: /tmp/dashboards
          provider:
            # enabling UI dashboards updated
            allowUiUpdates: true
            # enabling to structure dashboards folder based on the k8s-sidecar-target-directory
            foldersFromFilesStructure: true
    kube-state-metrics:
      rbac:
        extraRules:
        % if addon_operator['kasopePlatformEnabled'] == 'true':
        - apiGroups: ["medusa.k8ssandra.io"]
          resources: ["medusabackupjobs"]
          verbs: ["list", "watch"]
        % endif       
      customResourceState:
        enabled: true
        config:
          kind: CustomResourceStateMetrics
          spec:
            resources:
              % if addon_operator['kasopePlatformEnabled'] == 'true':
              - groupVersionKind:
                  group: "medusa.k8ssandra.io"
                  kind: "MedusaBackupJob"
                  version: "v1alpha1"
                labelsFromPath:
                  name: [metadata, name]
                metrics:
                  - name: "finishedMedusaBackups"
                    help: "finished backups"
                    each:
                      type: Info
                      info:                          
                        path: [status, finished]
                        labelsFromPath:
                          ref: []                        
                  - name: "failedMedusaBackups"
                    help: "failed backups"
                    each:
                      type: Info
                      info:                          
                        path: [status, failed]
                        labelsFromPath:
                          ref: []  
              % endif
    prometheus:
      enabled: true
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
      nodeSelector:
        dedicated-nodes: platform-masters
      % endif
      prometheusSpec:
        retention: 12d
        externalLabels:
          country: need-to-define
          customer: need-to-define
          datacenter: need-to-define
          environment: need-to-define
        enableRemoteWriteReceiver: true
        tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
        % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
        nodeSelector:
          dedicated-nodes: platform-masters
        % endif
        storageSpec:
          volumeClaimTemplate:
            spec:
              resources:
                requests:
                  storage: 50Gi
        % if values['global']['configurationProfile'] != 'dev':
        additionalAlertManagerConfigs:
          - static_configs:
              - targets:
                  - "alertmanager.alert.k8s.qvantel.net:9096"
        % endif
        additionalScrapeConfigs: |
          - job_name: 'kubernetes-pods'
            kubernetes_sd_configs:
            - role: pod
            relabel_configs:  # If first two labels are present, pod should be scraped  by the istio-secure job.
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
              action: keep
              regex: true
            # Keep target if there's no sidecar or if prometheus.io/scheme is explicitly set to "http"
            - source_labels: [__meta_kubernetes_pod_annotation_sidecar_istio_io_status, __meta_kubernetes_pod_annotation_prometheus_io_scheme]
              action: keep
              regex: ((;.*)|(.*;http))
            - source_labels: [__meta_kubernetes_pod_annotation_istio_mtls]
              action: drop
              regex: (true)
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
              action: replace
              target_label: __metrics_path__
              regex: (.+)
            - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
              action: replace
              regex: ([^:]+)(?::\d+)?;(\d+)
              replacement: $1:$2
              target_label: __address__
            - action: labelmap
              regex: __meta_kubernetes_pod_label_(.+)
            - source_labels: [__meta_kubernetes_namespace]
              action: replace
              target_label: namespace
            - source_labels: [__meta_kubernetes_pod_name]
              action: replace
              target_label: pod_name
            - source_labels: [__meta_consul_node]
              separator: ;
              regex: (.*)
              target_label: node
              replacement: $1
              action: replace
          - job_name: podMonitor/metrics/kafka-resources-metrics/0
            honor_timestamps: true
            scrape_interval: 30s
            scrape_timeout: 10s
            metrics_path: /metrics
            scheme: http
            follow_redirects: true
            relabel_configs:
            - source_labels: [job]
              separator: ;
              regex: (.*)
              target_label: __tmp_prometheus_job_name
              replacement: $1
              action: replace
            - source_labels: [__meta_kubernetes_pod_label_strimzi_io_kind]
              separator: ;
              regex: Kafka|KafkaConnect|KafkaMirrorMaker|KafkaMirrorMaker2
              replacement: $1
              action: keep
            - source_labels: [__meta_kubernetes_pod_container_port_name]
              separator: ;
              regex: tcp-prometheus
              replacement: $1
              action: keep
            - source_labels: [__meta_kubernetes_namespace]
              separator: ;
              regex: (.*)
              target_label: namespace
              replacement: $1
              action: replace
            - source_labels: [__meta_kubernetes_pod_container_name]
              separator: ;
              regex: (.*)
              target_label: container
              replacement: $1
              action: replace
            - source_labels: [__meta_kubernetes_pod_name]
              separator: ;
              regex: (.*)
              target_label: pod
              replacement: $1
              action: replace
            - separator: ;
              regex: (.*)
              target_label: job
              replacement: metrics/kafka-resources-metrics
              action: replace
            - separator: ;
              regex: (.*)
              target_label: endpoint
              replacement: tcp-prometheus
              action: replace
            - separator: ;
              regex: __meta_kubernetes_pod_label_(strimzi_io_.+)
              replacement: $1
              action: labelmap
            - source_labels: [__meta_kubernetes_namespace]
              separator: ;
              regex: (.*)
              target_label: namespace
              replacement: $1
              action: replace
            - source_labels: [__meta_kubernetes_pod_name]
              separator: ;
              regex: (.*)
              target_label: kubernetes_pod_name
              replacement: $1
              action: replace
            - source_labels: [__meta_kubernetes_pod_node_name]
              separator: ;
              regex: (.*)
              target_label: node_name
              replacement: $1
              action: replace
            - source_labels: [__meta_kubernetes_pod_host_ip]
              separator: ;
              regex: (.*)
              target_label: node_ip
              replacement: $1
              action: replace
            - source_labels: [__address__]
              separator: ;
              regex: (.*)
              modulus: 1
              target_label: __tmp_hash
              replacement: $1
              action: hashmod
            - source_labels: [__tmp_hash]
              separator: ;
              regex: "0"
              replacement: $1
              action: keep
            kubernetes_sd_configs:
            - role: pod
              kubeconfig_file: ""
              follow_redirects: true
              namespaces:
                names:
                - platform
