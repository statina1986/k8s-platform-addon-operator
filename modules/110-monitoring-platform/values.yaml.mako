monitoringPlatform:
  # -- If enabled, configures alertmanager with 3 replicas and other HA parameters
  alertManagerHighAvailability: false
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
      istio: ${addon_operator['istioPlatformEnabled']}
      kasope: ${addon_operator['kasopePlatformEnabled']}
      consul: ${addon_operator['consulPlatformEnabled']}
      vault: ${addon_operator['vaultPlatformEnabled']}
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
      type: statefulset
      replicas: 3
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    alloy:
      clustering:
        enabled: true
      extraPorts:
      - name: otlp-grpc
        port: 4318
        targetPort: 4318
        protocol: "TCP"
      - name: otlp-http
        port: 4317
        targetPort: 4317
        protocol: "TCP"
      extraEnv:
      - name: PROMETHEUS_ENDPOINT
        value: "http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-prometheus.${values['global']['platformNamespace']}.svc.cluster.local.:9090"
      - name: TEMPO_ENDPOINT
        value: "http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-tempo-distributor.${values['global']['platformNamespace']}.svc.cluster.local.:4317"
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
              traces  = [otelcol.exporter.otlp.tempo.input]
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
            
          otelcol.exporter.otlp "tempo" {
            // Send traces to a locally running Tempo without TLS enabled.
            client {
              endpoint = env("TEMPO_ENDPOINT")
              tls {
                insecure = true
                insecure_skip_verify = true
              }
            }
          }
  beyla:
    enabled: false
    global:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
    service:
      enabled: true
      labels:
        release: "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    config:
      data:
        # Contents of the actual Beyla configuration file
        discovery:
          services:
            - k8s_namespace: ${values['global']['appsNamespace']}           
        routes:
          unmatched: heuristic
        otel_metrics_export:
          endpoint: http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-alloy.${values['global']['platformNamespace']}.svc.cluster.local.:4317
        otel_traces_export:
          endpoint: http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-alloy.${values['global']['platformNamespace']}.svc.cluster.local.:4317
        attributes:
          kubernetes:
            enable: true
        internal_metrics:
          prometheus:
            port: 9090
            path: /metrics 
  tempo-distributed:
    enabled: false
    global:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
    metaMonitoring:
      serviceMonitor:
        enabled: true
        labels:
          release: "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    serviceAccount:
      create: false
      name: platform
    memcached:
      image:
        % if 'containerRegistryBase' in values['global']:
        repository: library/memcached
        % endif
    traces:
      otlp:
        grpc:
          enabled: true
        http:
          enabled: true
    metricsGenerator:
      enabled: true
      config:
        storage:
          remote_write:
            - url: "http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-prometheus.${values['global']['platformNamespace']}.svc.cluster.local.:9090/api/v1/write"
    global_overrides:
      defaults:
        metrics_generator:
          processors:
            - service-graphs
            - span-metrics
      per_tenant_override_config: /runtime-config/overrides.yaml
    overrides:
      defaults:
        metrics_generator:
          processors:
            - service-graphs
            - span-metrics
    storage:
      trace:
        backend: local #s3 to be changed 
        local:
          path: /var/tempo/traces
        wal:
          path: /var/tempo/wal
        #s3:
        #  endpoint: s3.ap-south-1.amazonaws.com  ### qv-platform-test endpoint
        #  bucket: qv-platform-test-tempo-traces  ### qv-platform-test bucket
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
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    secretsExporter:
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
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
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
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
            regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']})
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
            regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']})
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
    kubeEtcd:
      enabled: false
    kubeProxy:
      enabled: false
    kubeDns:
      enabled: false
    coreDns:
      enabled: false
    kubeApiServer:
      enabled: true
    kubeControllerManager:
      enabled: false
    kubelet:
      enabled: true
    kubeScheduler:
      enabled: false
    kubernetesServiceMonitors:
      enabled: true
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
      % if values.get('monitoringPlatform', {}).get('alertManagerHighAvailability', False):
      podDisruptionBudget: ## One pod operational all the time
        enabled: true
        minAvailable: 1
      servicePerReplica: ## To allow traffic separation to each pod
        enabled: true
      % endif
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
        % if values['global']['multiZone']['enabled']:
        topologySpreadConstraints:
          - labelSelector:
              matchLabels:
                app.kubernetes.io/name: alertmanager
            maxSkew: 1
            topologyKey: topology.kubernetes.io/zone
            whenUnsatisfiable: DoNotSchedule
        % endif
        % if values.get('monitoringPlatform', {}).get('alertManagerHighAvailability', False):
        replicas: 3
        podAntiAffinity: "hard"
        podAntiAffinityTopologyKey: kubernetes.io/hostname
        storage:
          volumeClaimTemplate: ## To persist all the created silences
            spec:
              resources:
                requests:
                  storage: 2Gi
        % endif
          
    prometheusOperator:
      % if values['global']['deployOperators'] == "false":
      enabled: false
      % else:
      enabled: true
      % endif
      % if values['global']['clusterwideResources'] == "false":
      namespaces:
        releaseNamespace: true
        # additional:
        #   - platform
        #   - qvantel
      kubeletService:
        namespace: ${values['global']['platformNamespace']}
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
      serviceAccount:
        create: false
        name: platform
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
      serviceAccount:
        create: false
        name: platform
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
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.2_202508131123_master_e140ddde
      downloadDashboardsImage:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
           % endif
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.2_202508131123_master_e140ddde
      initChownData:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
           % endif
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.2_202508131123_master_e140ddde
      extraContainerVolumes:
        - name: grafana-plugins
          emptyDir: { }
      extraVolumeMounts:
        - name: grafana-plugins
          mountPath: /var/lib/grafana/plugins
      extraInitContainers: 
        - name: plugin-sidecar
          % if 'containerRegistryBase' in values['global']:
          image: ${values['global']['containerRegistryBase']}/platform/grafana-plugins:1.2.0_7_e03920fe8
          % else:
          image: platform.artifactory.qvantel.net/platform/grafana-plugins:1.2.0_7_e03920fe8
          % endif
          command: ["/bin/sh", "-c"]
          args:
            - "for file in /tmp/*.zip; do unzip -o -q \"$file\" -d /var/lib/grafana/plugins; done"
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
      % if addon_operator['elasticsearchPlatformEnabled'] == 'true':
      envFromSecrets: 
        - name: "logsearch-es-elastic-user"
      % endif
      % if addon_operator['logsearchPlatformEnabled'] == 'true':
      envFromSecrets: 
        - name: "logsearch-elastic"
      % endif
      datasources:
        platform.yaml:
          apiVersion: 1
          datasources:
            - name: Loki
              type: loki
              % if values['global']['configurationProfile'] == 'dev' and values['global']['deployOperators'] == "true":
              url: http://loki-platform.${values['global']['platformNamespace']}.svc.cluster.local.:3100
              % endif
              % if values['global']['configurationProfile'] == 'dev' and values['global']['deployOperators'] == "false":
              url: http://loki-platform.${values['global']['operatorNamespace']}.svc.cluster.local.3100
              % endif
              % if values['global']['configurationProfile'] != 'dev' and values['global']['deployOperators'] == "true":
              url: http://loki-read.${values['global']['platformNamespace']}.svc.cluster.local.:3100
              % endif
              % if values['global']['configurationProfile'] != 'dev' and values['global']['deployOperators'] == "false":
              url: http://loki-read.${values['global']['operatorNamespace']}.svc.cluster.local.:3100
              % endif
              % if 'tempo-distributed' in values['monitoringPlatform'] and values['monitoringPlatform']['tempo-distributed']:
              jsonData:
                derivedFields:
                  - name: TraceID
                    matcherRegex: <%text>"\\\"trace_token\\\":\\\"(.+)\\\""</%text>
                    url: <%text>"$${__value.raw}"</%text>
                    urlDisplayLabel: "View trace"
                    datasourceUid: Tempo
              % endif
            % if 'tempo-distributed' in values['monitoringPlatform'] and values['monitoringPlatform']['tempo-distributed']:
            - name: Tempo
              type: tempo              
              url: http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-tempo-query-frontend.${values['global']['platformNamespace']}.svc.:3100
              jsonData:
                serviceMap:
                  datasourceUid: 'prometheus'
                nodeGraph:
                  enabled: true
                tracesToLogsV2:
                  datasourceUid: 'Loki'
                  spanStartTimeShift: '-1h'
                  spanEndTimeShift: '1h'
                  tags: [{ key: 'service.name', value: 'service_name' }]
                  filterByTraceID: true
                  filterBySpanID: false
                  customQuery: true
                  query: <%text>"{$${__tags}} |~ \"$${__span.traceId}\" | json | line_format `[{{`{{.trace_token}}`}}] {{`{{.log_level}}`}} {{`{{.logger_name}}`}} {{`{{.message}}`}}`"</%text>
            % endif
            % if addon_operator['elasticsearchPlatformEnabled'] == 'true':
            - name: Elasticsearch-Ingress
              type: elasticsearch
              access: http
              % if values['global']['deployOperators'] == "true":
              url: http://logsearch-es-logsearch.${values['global']['platformNamespace']}.svc.cluster.local.:9200
              % else:
              url: http://logsearch-es-logsearch.${values['global']['operatorNamespace']}.svc.cluster.local.:9200
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
              url: http://logsearch-es-logsearch.${values['global']['platformNamespace']}.svc.cluster.local.:9200
              % else:
              url: http://logsearch-es-logsearch.${values['global']['operatorNamespace']}.svc.cluster.local.:9200
              % endif
              basicAuth: true
              basicAuthUser: elastic
              database: application*
              isDefault: false
              jsonData:
                timeField: "@timestamp"
              secureJsonData:
                basicAuthPassword: <%text>${elastic}</%text>
            % endif
            % if addon_operator['logsearchPlatformEnabled'] == 'true':
            - name: Elasticsearch-Ingress
              type: elasticsearch
              access: http
              % if values['global']['deployOperators'] == "true":
              url: http://${values['global']['helmReleaseNamePrefix']}logsearch-platform.${values['global']['platformNamespace']}.svc.cluster.local.:9200
              % else:
              url: http://${values['global']['helmReleaseNamePrefix']}logsearch-platform.${values['global']['operatorNamespace']}.svc.cluster.local.:9200
              % endif
              basicAuth: true
              basicAuthUser: elastic
              database: ingress*
              isDefault: false
              jsonData:
                timeField: "@timestamp"
              secureJsonData:
                basicAuthPassword: <%text>${elasticsearch-password}</%text>
            - name: Elasticsearch-Application
              type: elasticsearch
              access: http
              % if values['global']['deployOperators'] == "true":
              url: http://${values['global']['helmReleaseNamePrefix']}logsearch-platform.${values['global']['platformNamespace']}.svc.cluster.local.:9200
              % else:
              url: http://${values['global']['helmReleaseNamePrefix']}logsearch-platform.${values['global']['operatorNamespace']}.svc.cluster.local.:9200
              % endif
              basicAuth: true
              basicAuthUser: elastic
              database: application*
              isDefault: false
              jsonData:
                timeField: "@timestamp"
              secureJsonData:
                basicAuthPassword: <%text>${elasticsearch-password}</%text>
            % endif
        business.yaml:
          apiVersion: 1
          datasources:
            - name: kpitool
              type: yesoreyeram-infinity-datasource
              uid: jEggJhu4k
              isDefault: false

      grafana.ini:
        plugins:
          preinstall_disabled: true
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
          token_url: http://qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local./auth/realms/qvantel/protocol/openid-connect/token
          api_url: http://qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local./auth/realms/qvantel/protocol/openid-connect/userinfo
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
              regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']})
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
      serviceAccount:
        create: false
        name: platform
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
            regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']})
            action: keep
        relabelings:
          - sourceLabels: [__meta_kubernetes_namespace]
            separator: ;
            regex: ^(.*)$
            targetLabel: namespace
            replacement: $1
            action: replace
      % endif
      serviceAccount:
        create: false
        name: "platform"
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
        # we need to put something here in order to add additionalAlertRelabelConfigs to prometheus
        additionalAlertRelabelConfigs: "Actual value not important, will be overridden from additionalAlertRelabelConfigAsMap"
        additionalAlertRelabelConfigAsMap:
          # critical severity to severity_qvantel SL3
          qvantelSeverityChange1: 
            action: replace
            regex: critical
            replacement: SL3
            source_labels:
            - severity
            target_label: severity_qvantel
          # warning,info or none severity to severity_qvantel SL4
          qvantelSeverityChange2:
            action: replace
            regex: (warning|info|none)
            replacement: SL4
            source_labels:
            - severity
            target_label: severity_qvantel
          # adapt severtiy_qvantel to SL2 for specific alerts
          qvantelSeverityChange3:
            action: replace
            regex: AppFrequentDeaths|BSSAPIExcessiveFailingGET|FailingPods|PendingPods|PostgreSQLRamLimitsCritical|PostgreSQLTempFilesCritical|KubePersistentVolumeFillingUp|Frequent5XXCalls
            replacement: SL2
            source_labels:
            - alertname
            target_label: severity_qvantel    
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
                  - "alertmanager-secondary.alert.k8s.qvantel.net:9096"
                  - "alertmanager-tertiary.alert.k8s.qvantel.net:9096"
        % endif
        additionalScrapeConfigsAsMap:
          kubernetes-pods:
            kubernetes_sd_configs:
            - role: pod
            relabel_configs:  # If first two labels are present, pod should be scraped  by the istio-secure job.
            % if values['global']['antreaCNIenabled'] == "true":
            - source_labels: [__meta_kubernetes_pod_label_app]
              action: drop
              regex: antrea
            % endif
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
              regex: (${values['global']['platformNamespace']}|${values['global']['appsNamespace']})
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
          % if addon_operator['istioIngressEnabled'] == 'true':
          envoy-stats:
            metrics_path: /stats/prometheus
            kubernetes_sd_configs:
            - role: pod
            relabel_configs:
            - source_labels: [__meta_kubernetes_pod_container_port_name]
              action: keep
              regex: '.*-envoy-prom'
          % endif
          % if values['global']['antreaCNIenabled'] == "true":
          antrea-controllers:
            kubernetes_sd_configs:
            - role: endpoints
            scheme: https
            tls_config:
              ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              insecure_skip_verify: true
            bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
            relabel_configs:
            - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_pod_container_name]
              action: keep
              regex: kube-system;antrea-controller
            - source_labels: [__meta_kubernetes_pod_node_name, __meta_kubernetes_pod_name]
              target_label: instance
          antrea-agents:
            kubernetes_sd_configs:
            - role: pod
            scheme: https
            tls_config:
              ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              insecure_skip_verify: true
            bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
            relabel_configs:
            - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_pod_container_name]
              action: keep
              regex: kube-system;antrea-agent
            - source_labels: [__meta_kubernetes_pod_node_name, __meta_kubernetes_pod_name]
              target_label: instance
          % endif
        additionalScrapeConfigs: |
          {{- range $k, $v := .Values.prometheus.prometheusSpec.additionalScrapeConfigsAsMap }}
          - job_name: '{{ $k }}'
          {{ $v | toYaml | indent 2}}
          {{- end }}