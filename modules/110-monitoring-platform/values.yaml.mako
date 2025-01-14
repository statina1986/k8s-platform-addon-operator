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
    integrations:
      opsgenie: false
    #Modules variables to control alerts and dashboards deployed based on the modules already deployed
    modules:
      cnpg: ${addon_operator['cnpgPostgresPlatformEnabled']}
      kafka: ${addon_operator['kafkaPlatformEnabled']}
      loki: ${addon_operator['lokiPlatformEnabled']}
      vector: ${addon_operator['vectorPlatformEnabled']}
      kasope: ${addon_operator['kasopePlatformEnabled']}
      consul: ${addon_operator['consulPlatformEnabled']}
      vault: ${addon_operator['vaultPlatformEnabled']}
      istio: ${addon_operator['istioPlatformEnabled']}
      elasticsearch: ${addon_operator['elasticsearchPlatformEnabled']}
      mariadb: ${addon_operator['mariadbOperatorPlatformEnabled']}
      redis: ${addon_operator['redisPlatformEnabled']}
      rabbitmq: ${addon_operator['rabbitmqPlatformEnabled']}
      mongodb: ${addon_operator['mongodbPlatformEnabled']}
  alloy:
    enabled: false
    global:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
    crds:
      create: false
    controller:
      type: deployment
      replicas: 1
    alloy:
      mode: flow
      extraPorts:
      - name: http-traces
        port: 4318
        targetPort: 4318
        protocol: "TCP"
      extraEnv:
      - name: PROMETHEUS_ENDPOINT
        value: "http://${values['global']['helmReleaseNamePrefix']}monitoring-platform.${values['global']['platformNamespace']}.svc:9090"
      - name: TEMPO_ENDPOINT
        value: "http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-tempo.${values['global']['platformNamespace']}.svc:4318"
      configMap:
        create: true
        content: |
          otelcol.receiver.otlp "default" {
            grpc {}
            http {}
          
            output {
              metrics = [otelcol.processor.batch.default.input]
              traces = [otelcol.processor.batch.default.input]
            }
          }
            
          otelcol.processor.batch "default" {
            output {
              metrics = [otelcol.exporter.prometheus.default.input]
              traces  = [otelcol.exporter.otlphttp.tempo.input]
            }
          }
            
          otelcol.exporter.prometheus "default" {
            forward_to = [prometheus.remote_write.prometheus.receiver]
          }
            
          prometheus.remote_write "prometheus" {
            endpoint {
              url = env("PROMETHEUS_ENDPOINT") + "/api/v1/write"
              }
            }
            
          otelcol.exporter.otlphttp "tempo" {
            // Send traces to a locally running Tempo without TLS enabled.
            client {
              endpoint = env("TEMPO_ENDPOINT")
            }
          }
  beyla:
    enabled: false
    global:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
    serviceAccount:
      create: false
      name: platform
    config:
      data:
        # Contents of the actual Beyla configuration file
        discovery:
          services:
            - k8s_namespace: ${values['global']['appsNamespace']}           
        routes:
          unmatched: heuristic
        otel_metrics_export:
          endpoint: http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-alloy.${values['global']['platformNamespace']}.svc:4318
        otel_traces_export:
          endpoint: http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-alloy.${values['global']['platformNamespace']}.svc:4318
        attributes:
          kubernetes:
            enable: true            
  tempo:
    enabled: false
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    tempo:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/grafana/tempo
      % endif
      storage:
        trace:
          backend: local #change to s3 
          local:
            path: /var/tempo/traces
          wal:
            path: /var/tempo/wal
        #  s3:
        #    endpoint: s3.eu-south-1.amazonaws.com  ### Need to set to correct endpoint
        #    bucket: tempo-traces
      metricsGenerator:
        enabled: true
        remoteWriteUrl: "http://${values['global']['helmReleaseNamePrefix']}monitoring-platform.${values['global']['platformNamespace']}:9090/api/v1/write"
        send_exemplars: true 
  x509-certificate-exporter:
    enabled: true
    % if values['global']['clusterwideResources'] == "false":
    rbac:
      create: false
      secretsExporter:
        serviceAccountName: platform
    % endif
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
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
    secretsExporter:
      % if values['global']['namespaceRestricted'] == "true":
      includeNamespaces:
        - ${values['global']['platformNamespace']}
      % endif
      resources:
        limits:
          cpu: 250m
          memory: 300Mi
        requests:
          cpu: 20m
          memory: 20Mi 
      podExtraLabels:
        "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    hostPathsExporter:
      podExtraLabels:
        "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    service:
      extraLabels:
        "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    prometheusServiceMonitor:
      extraLabels:
        "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    prometheusRules:
      extraLabels:
        "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
  prometheus-blackbox-exporter:
    enabled: true
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % endif
    pspEnabled: false
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
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
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
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
    serviceAccount:
      create: false
      name: platform
    extraArgs:
      scraping-interval: 60
    serviceMonitor:
      enabled: true
      labels:
        "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
  prometheus-consul-exporter:
    enabled: true
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/prom/consul-exporter
      % endif
      tag: v0.5.0
    rbac:
      pspEnabled: false
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    consulServer: consul-consul-server:8500
    serviceMonitor:
      labels: 
        "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
      enabled: true
      interval: 30s
      telemetryPath: /metrics
  kube-prometheus-stack:
    enabled: true
    fullnameOverride: ${values['global']['helmReleaseNamePrefix']}monitoring-platform
    % if values['global']['namespaceRestricted'] == "true":
    kubelet:
      serviceMonitor:
        cAdvisorMetricRelabelings:
          - sourceLabels: [ namespace ]
            regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']}|kube-system)
            action: keep
        cAdvisorRelabelings:
          - sourceLabels: [__meta_kubernetes_namespace]
            separator: ;
            regex: ^(.*)$
            targetLabel: namespace
            replacement: $1
            action: replace
          - sourceLabels: [__metrics_path__]
            targetLabel: metrics_path
            action: replace
        metricRelabelings:
          - sourceLabels: [ namespace ]
            regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']}|kube-system)
            action: keep
        relabelings:
          - sourceLabels: [__meta_kubernetes_namespace]
            separator: ;
            regex: ^(.*)$
            targetLabel: namespace
            replacement: $1
            action: replace
          - sourceLabels: [__metrics_path__]
            targetLabel: metrics_path
            action: replace
    % endif
    % if values['global']['clusterwideResources'] == "false":
    crds:
      enabled: false
    kubernetesServiceMonitors:
      enabled: false
    global:
      rbac:
        create: false
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
    defaultRules:
      create: true
      rules:
        kubernetesStorage: false
        kubeApiserverSlos: false
        kubeSchedulerAlerting: false
        kubeControllerManager: false
    alertmanager:
      alertmanagerSpec:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
        tolerations:
          - key: "${values['global']['platformMastersKey']}"
            value: "${values['global']['platformMastersValue']}"
            operator: "Equal"
            effect: "NoSchedule"
          
    prometheusOperator:
      % if values['global']['deployOperators'] == "false":
      enabled: false
      % else:
      enabled: true
      % endif
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      prometheusConfigReloader:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
      admissionWebhooks:
        % if values['global']['clusterwideResources'] == "false":
        enabled: false
        % endif
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
        patch:
          image:
            % if 'containerRegistryBase' in values['global']:
            registry: ${values['global']['containerRegistryBase']}
            % endif
          tolerations:
          - key: "${values['global']['platformMastersKey']}"
            value: "${values['global']['platformMastersValue']}"
            operator: "Equal"
            effect: "NoSchedule"
      thanosImage:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
    grafana:    
      enabled: true
      % if values['global']['clusterwideResources'] == "false":
      rbac:
        namespaced: true
      % endif
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
        repository: grafana/grafana-enterprise
      testFramework:
        image: 
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
      downloadDashboardsImage:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
      initChownData:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          repository: ubi9/ubi-minimal
          tag: 9.4-1194
           % endif
      extraContainerVolumes:
        - name: grafana-plugins
          emptyDir: { }
      extraVolumeMounts:
        - name: grafana-plugins
          mountPath: /var/lib/grafana/plugins
      extraInitContainers: 
        - name: plugin-sidecar
          % if 'containerRegistryBase' in values['global']:
          image: ${values['global']['containerRegistryBase']}/platform/grafana-plugins:1.2.0_4_f26bb6e90
          % else:
          image: platform.artifactory.qvantel.net/platform/grafana-plugins:1.2.0_4_f26bb6e90
          % endif
          command: ["/bin/sh", "-c"]
          args:
          - unzip /tmp/*.zip -d /var/lib/grafana/plugins
          volumeMounts:
            - name: grafana-plugins
              mountPath: /var/lib/grafana/plugins
      deploymentStrategy:
        type: Recreate
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
      % endif
      admin:
        existingSecret: grafana-admin-pass-secret
        passwordKey: grafanaAdminPassword
        userKey: adminUser
      serviceMonitor:
        labels:
          "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
      persistence:
        type: pvc
        enabled: true
        size: 30Gi
        finalizers:
          - kubernetes.io/pvc-protection
      % if addon_operator['elasticsearchPlatformEnabled'] == 'true' or values['global']['deployOperators'] == "false":
      envFromSecrets: 
        - name: "logsearch-es-elastic-user"
      % endif
      datasources:
        platform.yaml:
          apiVersion: 1
          datasources:
            - name: Loki
              type: loki
              % if values['global']['configurationProfile'] == 'dev' and values['global']['deployOperators'] == "true":
              url: http://loki-platform.${values['global']['platformNamespace']}.svc:3100
              % endif
              % if values['global']['configurationProfile'] == 'dev' and values['global']['deployOperators'] == "false":
              url: http://loki-platform.${values['global']['operatorNamespace']}.svc:3100
              % endif
              % if values['global']['configurationProfile'] != 'dev' and values['global']['deployOperators'] == "true":
              url: http://loki-read.${values['global']['platformNamespace']}.svc:3100
              % endif
              % if values['global']['configurationProfile'] != 'dev' and values['global']['deployOperators'] == "false":
              url: http://loki-read.${values['global']['operatorNamespace']}.svc:3100
              % endif
            - name: Tempo
              type: tempo              
              url: http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-tempo.${values['global']['platformNamespace']}.svc:3100
            - name: Elasticsearch-Ingress
              type: elasticsearch
              access: http
              % if values['global']['deployOperators'] == "true":
              url: http://logsearch-es-logsearch.${values['global']['platformNamespace']}.svc:9200
              % else:
              url: http://logsearch-es-logsearch.${values['global']['operatorNamespace']}.svc:9200
              % endif
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
              % if values['global']['deployOperators'] == "true":
              url: http://logsearch-es-logsearch.${values['global']['platformNamespace']}.svc:9200
              % else:
              url: http://logsearch-es-logsearch.${values['global']['operatorNamespace']}.svc:9200
              % endif
              basicAuth: true
              basicAuthUser: elastic
              database: application*
              isDefault: false
              jsonData:
                timeField: "@timestamp"
              secureJsonData:
                basicAuthPassword: <%text>${elastic}</%text>
        business.yaml:
          apiVersion: 1
          datasources:
            - name: kpitool
              type: yesoreyeram-infinity-datasource
              uid: jEggJhu4k
              isDefault: false

      grafana.ini:
        auth.anonymous:
          enabled: false
        dataproxy:
          timeout: 310
        server:
          root_url: https://grafana${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}
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
          auth_url: https://auth${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}/auth/realms/qvantel/protocol/openid-connect/auth # override if needed in the target environment values file
          signout_redirect_url: https://auth${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}/auth/realms/qvantel/protocol/openid-connect/logout # override if needed in the target environment values file
          token_url: http://qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local/auth/realms/qvantel/protocol/openid-connect/token
          api_url: http://qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local/auth/realms/qvantel/protocol/openid-connect/userinfo
          role_attribute_path: contains(realm_access.roles[*], 'grafana_admin') && 'Admin' || contains(realm_access.roles[*], 'grafana_server_admin') && 'GrafanaAdmin' || contains(realm_access.roles[*], 'grafana_editor') && 'Editor' || contains(realm_access.roles[*], 'grafana_viewer') && 'Viewer'
          allow_assign_grafana_admin: true
          role_attribute_strict: true
          use_pkce: true
      envFromSecret: grafana-keycloak-client-secret
      sidecar:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
        datasources:
          enabled: true
          defaultDatasourceEnabled: true
          maxLines: 1000
        dashboards:
          enabled: true
          % if values['global']['namespaceRestricted'] == "true":
          searchNamespace: 
            - ${values['global']['platformNamespace']}
            - ${values['global']['appsNamespace']}
          % endif
          label: grafana_dashboard
          labelValue: "1"
          annotations:
            grafana_folder: "Kubernetes"
          folder: /tmp/dashboards
          folderAnnotation: grafana_folder
          provider:
            # enabling UI dashboards updated
            allowUiUpdates: true
            # enabling to structure dashboards folder based on the k8s-sidecar-target-directory
            foldersFromFilesStructure: true
    % if values['global']['deployOperators'] == "false":
    nodeExporter:
      enabled: false
    % endif
    prometheus-node-exporter:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
    kube-state-metrics:
      % if values['global']['namespaceRestricted'] == "true":
      prometheus:
        monitor:
          metricRelabelings:
            - sourceLabels: [ namespace ]
              regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']}|kube-system)
              action: keep
          relabelings:
            - sourceLabels: [__meta_kubernetes_namespace]
              separator: ;
              regex: ^(.*)$
              targetLabel: namespace
              replacement: $1
              action: replace
      % endif
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
      rbac:
        % if values['global']['clusterwideResources'] == "false":
        useClusterRole: false
        % endif
        extraRules:
        % if addon_operator['kasopePlatformEnabled'] == 'true':
        - apiGroups: ["medusa.k8ssandra.io"]
          resources: ["medusabackupjobs"]
          verbs: ["list", "watch"]
        % endif       
      kubeRBACProxy:
        enabled: false
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
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
                  - name: "medusaBackupsFinishTime"
                    help: "backup finished timestamp"
                    each:
                      type: Gauge
                      gauge:
                        path: [status, finishTime]                        
                  - name: "failedMedusaBackups"
                    help: "failed backups"
                    each:
                      type: Info
                      info:                          
                        path: [status, failed]
                        labelsFromPath:
                          ref: []
              % endif
    thanosRuler:
      thanosRulerSpec:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
    prometheus:
      enabled: true
      % if values['global']['namespaceRestricted'] == "true":
      serviceMonitor:
        metricRelabelings:
          - sourceLabels: [ namespace ]
            regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']}|kube-system)
            action: keep
        relabelings:
          - sourceLabels: [__meta_kubernetes_namespace]
            separator: ;
            regex: ^(.*)$
            targetLabel: namespace
            replacement: $1
            action: replace
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
      prometheusSpec:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
        retention: 12d
        externalLabels:
          country: need-to-define
          customer: need-to-define
          datacenter: need-to-define
          environment: need-to-define
        enableRemoteWriteReceiver: true
        podMonitorSelector:
          matchLabels:
            "release": ${values['global']['helmReleaseNamePrefix']}monitoring-platform
        probeSelector:
          matchLabels:
            "release": ${values['global']['helmReleaseNamePrefix']}monitoring-platform
        ruleSelector:
          matchLabels:
            "release": ${values['global']['helmReleaseNamePrefix']}monitoring-platform
        scrapeConfigSelector:
          matchLabels:
            "release": ${values['global']['helmReleaseNamePrefix']}monitoring-platform
        serviceMonitorSelector:
          matchLabels:
            "release": ${values['global']['helmReleaseNamePrefix']}monitoring-platform
        tolerations:
          - key: "${values['global']['platformMastersKey']}"
            value: "${values['global']['platformMastersValue']}"
            operator: "Equal"
            effect: "NoSchedule"
        % if values['global']['platformMasters']:
        nodeSelector:
          ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
        % endif
        storageSpec:
          volumeClaimTemplate:
            spec:
              resources:
                requests:
                  storage: 50Gi
        % if values['global']['configurationProfile'] == 'prod':
        additionalAlertManagerConfigs:
          - static_configs:
              - targets:
                  - "alertmanager.alert.k8s.qvantel.net:9096"
        % endif
        additionalScrapeConfigsAsMap:
          kubernetes-pods:
            kubernetes_sd_configs:
            - role: pod
            relabel_configs:  # If first two labels are present, pod should be scraped  by the istio-secure job.
            - source_labels: [__meta_kubernetes_pod_label_app]
              action: drop
              regex: antrea
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
            % if values['global']['namespaceRestricted'] == "true":
            - source_labels: [__meta_kubernetes_namespace]
              action: keep
              regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']}|kube-system)
            % endif
          'podMonitor/metrics/kafka-resources-metrics/0' :
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
                - ${values['global']['platformNamespace']}
        additionalScrapeConfigs: |
          {{- range $k, $v := .Values.prometheus.prometheusSpec.additionalScrapeConfigsAsMap }}
          - job_name: '{{ $k }}'
          {{ $v | toYaml | indent 2}}
          {{- end }}