istioIngress:
  # -- Enables Pomerium Authorization proxy. This will affect only VirtualServices which have `pomeriumProtected: true` attributes
  pomeriumEnabled: false
  
  # -- Enables Public Ingress gateway
  publicIngressEnabled: false
  # -- Enable full request logging for Public Ingress gateway
  publicIngressLogFullRequest: false
  # -- Enable full response logging for Public Ingress gateway
  publicIngressLogFullResponse: false
  # -- Configure request buffering (in bytes) for Public Ingress gateway. Set to 0 for disabling buffering.
  publicIngressBufferHttpRequestSize: 0
  # -- Default security headers to filter out for Public Ingress gateway
  publicIngressRemoveSecurityHeadersDefaults:
    - x-envoy-upstream-service-time
    - server
  # -- Additional security headers to filter out for Public Ingress gateway
  publicIngressRemoveSecurityHeaders: []
  # -- Configuration for underlying `gateway` helm-chart for Public Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
  publicIngress:
    name: ${values['global']['helmReleaseNamePrefix']}public-ingress
    % if values['global']['configurationProfile'] in {'dev'}:
    replicaCount: 1
    % else:
    replicaCount: 3
    % endif
    podAnnotations:
      # this is to support zero downtime rollout (especially in EKS with NLB). On termination ingress pods will wait `drainDuration` second accepting and serving connections giving external loadbalancer time to drain and deregister target. 
      proxy.istio.io/config: |
        drainDuration: 30s
        terminationDrainDuration: 31s
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
        matchLabelKeys:
          - pod-template-hash
        labelSelector:
          matchLabels:
            istio: ${values['global']['helmReleaseNamePrefix']}public-ingress
    % endif
    autoscaling:
      enabled: false
      minReplicas: 3
      maxReplicas: 9
      targetCPUUtilizationPercentage: 80
    labels:
      istio-ingress: "true"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        memory: 1024Mi
    service:
      annotations:
        % if addon_operator['awsPlatformEnabled'] == 'true':
        service.beta.kubernetes.io/aws-load-balancer-type: "external"
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-internal: "false"
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=false
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-public
        % endif
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-public
        % else:
        {}
        % endif
  # -- List of  `Gateway` resources provisioned for Public Ingress gateway.
  publicIngressGateways:
  - name: ${values['global']['helmReleaseNamePrefix']}public-ingress
    spec:
      selector:
        istio: ${values['global']['helmReleaseNamePrefix']}public-ingress
      servers:
      - hosts:
        - '*'
        port:
          name: http
          number: 80
          protocol: HTTP
      - hosts:
        - '*'
        port:
          name: https
          number: 443
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: qvantel-wildcard

  # -- Enables Private Ingress gateway
  privateIngressEnabled: false
  # -- Enable full request logging for Private Ingress gateway
  privateIngressLogFullRequest: false
  # -- Enable full response logging for Private Ingress gateway
  privateIngressLogFullResponse: false
  # -- Configure request buffering (in bytes) for Private Ingress gateway. Set to 0 for disabling buffering.
  privateIngressBufferHttpRequestSize: 0
  # -- Default security headers to filter out for Private Ingress gateway
  privateIngressRemoveSecurityHeadersDefaults:
    - x-envoy-upstream-service-time
    - server
  # -- Additional security headers to filter out for Private Ingress gateway
  privateIngressRemoveSecurityHeaders: []
  # -- Configuration for underlying `gateway` helm-chart for Private Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
  privateIngress:
    name: ${values['global']['helmReleaseNamePrefix']}private-ingress
    % if values['global']['configurationProfile'] in {'dev'}:
    replicaCount: 1
    % else:
    replicaCount: 3
    % endif
    podAnnotations:
      # this is to support zero downtime rollout (especially in EKS with NLB). On termination ingress pods will wait `drainDuration` second accepting and serving connections giving external loadbalancer time to drain and deregister target. 
      proxy.istio.io/config: |
        drainDuration: 30s
        terminationDrainDuration: 31s
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
        matchLabelKeys:
          - pod-template-hash
        labelSelector:
          matchLabels:
            istio: ${values['global']['helmReleaseNamePrefix']}private-ingress
    % endif
    autoscaling:
      enabled: false
      minReplicas: 3
      maxReplicas: 9
      targetCPUUtilizationPercentage: 80
    labels:
      istio-ingress: "true"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        memory: 1024Mi
    service:
      ports:
      - name: status-port
        port: 15021
        protocol: TCP
        targetPort: 15021
      - name: http
        port: 80
        protocol: TCP
        targetPort: 80
      - name: https
        port: 443
        protocol: TCP
        targetPort: 443
      - name: rabbitmq
        port: 5672
        protocol: TCP
        targetPort: 5672
      - name: rabbitmq-stomp
        port: 61613
        protocol: TCP
        targetPort: 61613
      - name: rabbitmq-webstomp
        port: 15674
        protocol: TCP
        targetPort: 15674
      annotations:
        % if addon_operator['awsPlatformEnabled'] == 'true':
        service.beta.kubernetes.io/aws-load-balancer-type: "external"
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=false
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-private
        % endif
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-private
        % else:
        {}
        % endif
  # -- List of  `Gateway` resources provisioned for Private Ingress gateway.
  privateIngressGateways:
  - name: ${values['global']['helmReleaseNamePrefix']}private-ingress
    spec:
      selector:
        istio: ${values['global']['helmReleaseNamePrefix']}private-ingress
      servers:
      - hosts:
        - '*'
        port:
          name: http
          number: 80
          protocol: HTTP
      - hosts:
        - '*'
        port:
          name: https
          number: 443
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: qvantel-wildcard
      - hosts:
        - '*'
        port:
          name: rabbitmq
          number: 5672
          protocol: TCP
      - hosts:
        - '*'
        port:
          name: rabbitmq-stomp
          number: 61613
          protocol: TCP
      - hosts:
        - '*'
        port:
          name: rabbitmq-webstomp
          number: 15674
          protocol: HTTP

  # -- Enables Integrations Http Ingress gateway
  integrationsHttpIngressEnabled: false
  # -- Enable full request logging for Integrations Http Ingress gateway
  integrationsHttpIngressLogFullRequest: false
  # -- Enable full response logging for Integrations Http Ingress gateway
  integrationsHttpIngressLogFullResponse: false
  # -- Configure request buffering (in bytes) for Integrations Http Ingress gateway. Set to 0 for disabling buffering.
  integrationsHttpIngressBufferHttpRequestSize: 0
  # -- Default security headers to filter out for Integrations Http Ingress gateway
  integrationsHttpIngressRemoveSecurityHeadersDefaults:
    - x-envoy-upstream-service-time
    - server
  # -- Additional security headers to filter out for Integrations Http Ingress gateway
  integrationsHttpIngressRemoveSecurityHeaders: []
  # -- Configuration for underlying `gateway` helm-chart for Integrations Http Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
  integrationsHttpIngress:
    name: ${values['global']['helmReleaseNamePrefix']}integrations-http-ingress
    % if values['global']['configurationProfile'] in {'dev'}:
    replicaCount: 1
    % else:
    replicaCount: 3
    % endif
    podAnnotations:
      # this is to support zero downtime rollout (especially in EKS with NLB). On termination ingress pods will wait `drainDuration` second accepting and serving connections giving external loadbalancer time to drain and deregister target. 
      proxy.istio.io/config: |
        drainDuration: 30s
        terminationDrainDuration: 31s
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
        matchLabelKeys:
          - pod-template-hash
        labelSelector:
          matchLabels:
            istio: ${values['global']['helmReleaseNamePrefix']}integrations-http-ingress
    % endif
    autoscaling:
      enabled: false
      minReplicas: 3
      maxReplicas: 9
      targetCPUUtilizationPercentage: 80
    labels:
      istio-ingress: "true"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        memory: 1024Mi
    service:
      annotations:
        % if addon_operator['awsPlatformEnabled'] == 'true':
        service.beta.kubernetes.io/aws-load-balancer-type: "external"
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=false
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-http
        % endif
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-http
        % else:
        {}
        % endif
  # -- List of  `Gateway` resources provisioned for Integrations Http Ingress gateway.
  integrationsHttpIngressGateways:
  - name: ${values['global']['helmReleaseNamePrefix']}integrations-http-ingress
    spec:
      selector:
        istio: ${values['global']['helmReleaseNamePrefix']}integrations-http-ingress
      servers:
      - hosts:
        - '*'
        port:
          name: http
          number: 80
          protocol: HTTP
      - hosts:
        - '*'
        port:
          name: https
          number: 443
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: qvantel-wildcard

  # -- Enables Integrations Non Http Ingress gateway
  integrationsNonHttpIngressEnabled: false
  # -- Enable full request logging for Integrations Non Http Ingress gateway
  integrationsNonHttpIngressLogFullRequest: false
  # -- Enable full response logging for Integrations Non Http Ingress gateway
  integrationsNonHttpIngressLogFullResponse: false
  # -- Configure request buffering (in bytes) for Integrations Non Http Ingress gateway. Set to 0 for disabling buffering.
  integrationsNonHttpIngressBufferHttpRequestSize: 0
  # -- Default security headers to filter out for Integrations Non Http Ingress gateway
  integrationsNonHttpIngressRemoveSecurityHeadersDefaults:
    - x-envoy-upstream-service-time
    - server
  # -- Additional security headers to filter out for Integrations Non Http Ingress gateway
  integrationsNonHttpIngressRemoveSecurityHeaders: []
  # -- Configuration for underlying `gateway` helm-chart for Integrations Non Http Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
  integrationsNonHttpIngress:
    name: ${values['global']['helmReleaseNamePrefix']}integrations-non-http-ingress
    % if values['global']['configurationProfile'] in {'dev'}:
    replicaCount: 1
    % else:
    replicaCount: 3
    % endif
    podAnnotations:
      # this is to support zero downtime rollout (especially in EKS with NLB). On termination ingress pods will wait `drainDuration` second accepting and serving connections giving external loadbalancer time to drain and deregister target. 
      proxy.istio.io/config: |
        drainDuration: 30s
        terminationDrainDuration: 31s
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
        matchLabelKeys:
          - pod-template-hash
        labelSelector:
          matchLabels:
            istio: ${values['global']['helmReleaseNamePrefix']}integrations-non-http-ingress
    % endif
    autoscaling:
      enabled: false
      minReplicas: 3
      maxReplicas: 9
      targetCPUUtilizationPercentage: 80
    labels:
      istio-ingress: "true"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        memory: 1024Mi
    service:
      annotations:
        % if addon_operator['awsPlatformEnabled'] == 'true':
        service.beta.kubernetes.io/aws-load-balancer-type: "external"
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=true
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-nonhttp
        % endif
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-nonhttp
        % else:
        {}
        % endif
      ports:
      - name: status-port
        port: 15021
        protocol: TCP
        targetPort: 15021
      - name: sftp
        port: 22
        protocol: TCP
        targetPort: 22
  # -- List of  `Gateway` resources provisioned for Integrations Non Http Ingress gateway.
  integrationsNonHttpIngressGateways:
  - name: ${values['global']['helmReleaseNamePrefix']}integrations-non-http-ingress
    spec:
      selector:
        istio: ${values['global']['helmReleaseNamePrefix']}integrations-non-http-ingress
      servers:
      - hosts:
        - '*'
        port:
          name: sftp
          number: 22
          protocol: TCP
  envoyFilters:
    instances:
      listener-timeout-tcp:
        enabled: false
        spec:
          configPatches:
          - applyTo: NETWORK_FILTER
            match:
              context: SIDECAR_INBOUND
              listener:
                filterChain:
                  filter:
                    name: envoy.filters.network.tcp_proxy
            patch:
              operation: MERGE
              value:
                name: envoy.filters.network.tcp_proxy
                typed_config:
                  '@type': type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                  idle_timeout: 168h
          - applyTo: NETWORK_FILTER
            match:
              context: SIDECAR_OUTBOUND
              listener:
                filterChain:
                  filter:
                    name: envoy.filters.network.tcp_proxy
            patch:
              operation: MERGE
              value:
                name: envoy.filters.network.tcp_proxy
                typed_config:
                  '@type': type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                  idle_timeout: 168h
      ingress-gateway-opts:
        enabled: false
        spec:
          configPatches:
          # Enable TCP Keepalives for ingress gateway HTTP(S) port (6443)
          # See https://github.com/istio/istio/issues/28879
          # (For some reason ingress gateways are not affected by global mesh keepalive options).
          - applyTo: LISTENER
            match:
              context: GATEWAY
              listener:
                name: 0.0.0.0_6443
                portNumber: 6443
            patch:
              operation: MERGE
              value:
                socket_options:
                - description: enable keep-alive
                  int_value: 1
                  level: 1
                  name: 9
                  state: STATE_PREBIND
                - description: idle time before first keep-alive probe is sent
                  int_value: 91  # 91 seconds
                  level: 6
                  name: 4
                  state: STATE_PREBIND
                - description: keep-alive interval
                  int_value: 11  # 11 seconds
                  level: 6
                  name: 5
                  state: STATE_PREBIND
                - description: keep-alive probes count
                  int_value: 5
                  level: 6
                  name: 6
                  state: STATE_PREBIND
    multiInstances:
      bss-integrator-ingress-gateway-opts:
        enabled: false
        variables:
          ports:
          - 3000
          - 2095
          - 2075
          - 2045
          - 2035
          - 2050
          - 2055
          - 10000
          - 3010
          - 2065
          - 2085
          - 9093
          - 9094
          - 9095
          - 9096
        specTemplate: |
          configPatches:
          {{- range .ports }}
          - applyTo: LISTENER
            match:
              context: GATEWAY
              listener:
                name: 0.0.0.0_{{ . }}
                portNumber: {{ . }}
            patch:
              operation: MERGE
              value:
                socket_options:
                - description: enable keep-alive
                  int_value: 1
                  level: 1
                  name: 9
                  state: STATE_PREBIND
                - description: idle time before first keep-alive probe is sent
                  int_value: 91
                  level: 6
                  name: 4
                  state: STATE_PREBIND
                - description: keep-alive interval
                  int_value: 11
                  level: 6
                  name: 5
                  state: STATE_PREBIND
                - description: keep-alive probes count
                  int_value: 5
                  level: 6
                  name: 6
                  state: STATE_PREBIND
          - applyTo: NETWORK_FILTER
            match:
              context: GATEWAY
              listener:
                name: 0.0.0.0_{{ . }}
                portNumber: {{ . }}
                filterChain:
                  filter:
                    name: "envoy.filters.network.http_connection_manager"
            patch:
              operation: MERGE
              value:
                name: "envoy.filters.network.http_connection_manager"
                typed_config:
                  "@type": "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager"
                  common_http_protocol_options:
                    idle_timeout: 24h
          {{- end }}
  destinationRules:
    instances:
      rabbitmq-hpd-dr:
        enabled: false
        spec:
          host: hpd-rabbitmq.platform.svc.cluster.local
          trafficPolicy:
            tls:
              mode: ISTIO_MUTUAL
            connectionPool:
              tcp:
                tcpKeepalive:
                  probes: 9
                  time: 65s
                  interval: 10s
      rabbitmq-dr:
        enabled: false
        spec:
          host: dna-rabbitmq.platform.svc.cluster.local
          trafficPolicy:
            tls:
              mode: ISTIO_MUTUAL
            connectionPool:
              tcp:
                tcpKeepalive:
                  probes: 9
                  time: 65s
                  interval: 10s
    multipleInstances:
      dna-destinationrules:
        enabled: false
        entries:
          rbs-master-xmlrpc-dr:
            host: rbs-master-xmlrpc.qvantel.svc.cluster.local
          rbs-xmlrpc-dr:
            host: rbs-xmlrpc.qvantel.svc.cluster.local
          zipkin-dr:
            host: dna-zipkin.qrp.svc.cluster.local
          vault-ui-dr:
            host: vault-ui.platform.svc.cluster.local
          sentry-ui-dr:
            host: dna-sentry-nginx.sentry.svc.cluster.local
          crm-gatekeeper-api-dr:
            host: crm-gatekeeper-api.qvantel.svc.cluster.local
          dnapy-navision-api-dr:
            host: dnapy-soap-navision.qvantel.svc.cluster.local
          bssapi-aggregator-dr:
            host: bssapi-aggregator.qrp.svc.cluster.local
          rbs-gatekeeper-api-dr:
            host: rbs-gatekeeper-api.qvantel.svc.cluster.local
          dnapy-rest-dil-listener-dr:
            host: dnapy-rest-dil-listener.qvantel.svc.cluster.local
          pyprov-network-listener-dr:
            host: pyprov-network-listener-8080.qvantel.svc.cluster.local
          orders-event-receiver-dr:
            host: orders-event-receiver.qrp.svc.cluster.local
          hybris-inventory-api-dr:
            host: hybris-inventory-api-8080.qvantel.svc.cluster.local
          hybris-shop-api-dr:
            host: dnapy-rest-bssapi-shop.qvantel.svc.cluster.local
          dnapy-mobile-id-api-v1-dr:
            host: dnapy-api-mobile-id.qvantel.svc.cluster.local
          mobile-id-api-dr:
            host: mobile-id-app-api.qvantel.svc.cluster.local
          hybris-gatekeeper-api-dr:
            host: hybris-gatekeeper-api.qvantel.svc.cluster.local
          dnapy-proq-dr:
            host: dnapy-web-proq.qvantel.svc.cluster.local
          billingui-backend-dr:
            host: billingui-backend.qvantel.svc.cluster.local
          billingui-frontend-log-proxy-dr:
            host: billingui-frontend-log-proxy-8181.qvantel.svc.cluster.local
          billingui-frontend-dr:
            host: billingui-frontend.qvantel.svc.cluster.local
          salestool-backend-telesales-dr:
            host: salestool-backend-telesales.qvantel.svc.cluster.local
          salestool-frontend-telesales-dr:
            host: salestool-frontend-telesales.qvantel.svc.cluster.local
          dnapy-robot-dr:
            host: dnapy-web-robot.qvantel.svc.cluster.local
          flex-app-store-dr:
            host: flex-app-store.qrp.svc.cluster.local
          catalog-deployer-dr:
            host: qflow-catalog-deployer.qrp.svc.cluster.local
          catalog-designer-dr:
            host: qflow-product-catalog-designer-9003.qrp.svc.cluster.local
          keycloak-auth-dr:
            host: operational-keycloak-8080.qvantel.svc.cluster.local
          operational-index-dr:
            host: operational-index-8080.qvantel.svc.cluster.local
          fake-dil-dr:
            host: fake-dil-admin.qvantel.svc.cluster.local
          peon-admin-frontend-dr:
            host: peon-admin-frontend.qvantel.svc.cluster.local
          peon-admin-backend-dr:
            host: peon-admin-backend-8080.qvantel.svc.cluster.local
          pyprov-admin-dr:
            host: pyprov-admin.qvantel.svc.cluster.local
          rbs-gatekeeper-admin-dr:
            host: rbs-gatekeeper-admin.qvantel.svc.cluster.local
          kafka-admin-web-dr:
            host: kafka-admin-web.qvantel.svc.cluster.local
          audit-admin-dr:
            host: audit-admin.qvantel.svc.cluster.local
          product-catalog-visualizer-dr:
            host: product-catalog-visualizer.qvantel.svc.cluster.local
          bssapi-documentation-dr:
            host: bssapi-documentation-service.qrp.svc.cluster.local
          dnapy-extcc-dr:
            host: dnapy-web-extcc.qvantel.svc.cluster.local
          salestool-backend-pos-dr:
            host: salestool-backend-pos.qvantel.svc.cluster.local
          salestool-frontend-pos-dr:
            host: salestool-frontend-pos.qvantel.svc.cluster.local
          dnapy-selfservice-dr:
            host: dnapy-web-selfservice.qvantel.svc.cluster.local
          dnapy-frontback-activation-dr:
            host: dnapy-frontback-activation.qvantel.svc.cluster.local
          activation-frontend-dr:
            host: activation-frontend.qvantel.svc.cluster.local
          bssapi-explorer-dr:
            host: bssapi-explorer.qrp.svc.cluster.local
          flex-admin-dr:
            host: flex-admin.qrp.svc.cluster.local
        specTemplate: |
          host: {{ .host }}
          trafficPolicy:
            tls:
              mode: ISTIO_MUTUAL

  # -- VirtualServices to be provisioned.
  # @default -- see values.yaml.mako
  virtualServices:
    # -- Common annotations for all VirtualServices resources provisioned
    annotations:
    # external-dns.alpha.kubernetes.io/target: my-global-load-balancer.cloud.com
    # -- Common base dns name to be used for all VirtualServices. `host` of VirtualServices will be set to <virtual-service-name><dnsSeparator><dnsBase>. By default values are taken from `global.ingressBaseUrl` and `global.ingressBaseUrlSeparator`
    dnsBase: ${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}
    # -- Qvantel applications namespace name. By default value is taken from `global.appsNamespace` and equal to `qvantel`
    appsNamespace: ${values['global']['appsNamespace']}
    # -- Qvantel platform namespace name. By default value is taken from `global.appsNamespace` and equal to `platform`
    platformNamespace: ${values['global']['platformNamespace']}
    # -- List of  `VirtualService` resources to be provisioned. It is a map, so it can be configuration may be inherited/extended in multiple valyes.yaml files.  
    # @default -- see values.yaml.mako
    instances: 
      # Product managed services    
      address-manager:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: addresses.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8000
      billing:
        enabled: false
        gateways:
          - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
          - retries:
              attempts: 0
            route:
              - destination:
                  host: rbs-billing-front.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 3003      
      bssapi:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: bssapi-aggregator.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
      bssapi-docs:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: bssapi-documentation-service.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8010
      bssapi-explorer:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
          - route:
            - destination:
                host: bssapi-explorer.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
      b2b-sales-tool:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
          - retries:
              attempts: 0
            route:
              - destination:
                  host: b2b-sales-tool-web.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 3000
      b2b-flex-ecare:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: b2b-flex-ecare-web.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 3000
      b2c-flex-ecare:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: b2c-flex-ecare-web.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 3000
      case-admin:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - match:
          - uri:
              exact: /
          redirect:
            uri: /caseadmin/sa/
        - route:
          - destination:
              host: case-admin.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8096
      case-management:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - match:
          - uri:
              exact: /
          redirect:
            uri: /casemanager/sa/
        - route:
          - destination:
              host: case-manager.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8092
      catalog-deployer:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: catalog-qflow-catalog-deployer.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
      catalog-designer:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - match:
          - uri:
              prefix: /websockets
          route:
          - destination:
              host: catalog-qflow-product-catalog-designer-9005.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 9005
        - route:
          - destination:
              host: catalog-qflow-product-catalog-designer-9003.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 9003
      cdt:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: cdt-frontend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 3001
      document-manager:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - match:
          - uri:
              prefix: /api/documents/render-template
          route:
          - destination:
              host: documents-doc-manager-dynamic-template.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 5001
        - match:
          - uri:
              prefix: /api/documents/
          route:
          - destination:
              host: documents-doc-manager-backend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
        - route:
          - destination:
              host: documents-doc-manager-frontend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 5000
      document-storage:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - match:
          - uri:
              prefix: /api/
          route:
          - destination:
              host: documents-doc-storage-backend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
        - match:
          - uri:
              prefix: /file/
          route:
          - destination:
              host: documents-doc-storage-backend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
        - match:
          - uri:
              prefix: /external-documents/
          route:
          - destination:
              host: documents-doc-storage-backend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
        - route:
          - destination:
              host: documents-doc-storage-frontend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
      flex-admin:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: flex-admin.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 21080
      flex-app-store:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: flex-app-store.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 21090
      flex-bpmn-executor:
        enabled: false
        gateways:
          - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
          - retries:
              attempts: 0
            route:
              - destination:
                  host: flex-bpmn-executor.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 21010
      flex-testing-bpmn-executor:
        enabled: false
        gateways:
          - private-ingress
        http:
          - retries:
              attempts: 0
            route:
              - destination:
                  host: flex-testing-bpmn-executor.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 21010
      graphql:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: graphql-graphql-bssapi.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8180
      kpitool:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: kpi-tool-front.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 4458
      mapp:
        enabled: false
        gateways:
          - ${values['global']['helmReleaseNamePrefix']}public-ingress
        http:
          - match:
            - uri:
                prefix: /uc/
            retries:
              attempts: 0
            route:
            - destination:
                host: graphql-graphql-bssapi.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8180
          - match:
            - uri:
                prefix: /images/
            retries:
              attempts: 0
            route:
            - destination:
                host: catalog-qflow-catalog-data.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
          - match:
            - uri:
                prefix: /file
            retries:
              attempts: 0
            route:
            - destination:
                host: documents-doc-storage-backend.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
          - match:
            - uri:
                prefix: /flow/
            retries:
              attempts: 0
            rewrite:
              uri: /
            route:
            - destination:
                host: mobile-flowable-api.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 21090
          - match:
            - uri:
                prefix: /web/static
            retries:
              attempts: 0
            rewrite:
              uri: /static
            route:
            - destination:
                host: mobile-flows-catalog-service.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
      message-manager:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: message-manager-wui.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 3003
      # mobile-ui-builder:
      #   enabled: false
      #   gateways:
      #     - ${values['global']['helmReleaseNamePrefix']}private-ingress
      #   http:
      #     - retries:
      #         attempts: 0
      #       route:
      #         - destination:
      #             host: mobile-ui-builder.${values['global']['appsNamespace']}.svc.cluster.local
      #             port:
      #               number: 21080
      # mockbank:
      #   enabled: false
      #   gateways:
      #   - ${values['global']['helmReleaseNamePrefix']}private-ingress
      #   http:
      #   - route:
      #     - destination:
      #         host: omnichannel-bank.${values['global']['appsNamespace']}.svc.cluster.local
      #         port:
      #           number: 3500
      mockoss:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: mockoss.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8000
      # pcb:
      #   enabled: false
      #   gateways:
      #   - ${values['global']['helmReleaseNamePrefix']}private-ingress
      #   http:
      #   - route:
      #     - destination:
      #         host: pcb.${values['global']['appsNamespace']}.svc.cluster.local
      #         port:
      #           number: 8095
      # pos:
      #   enabled: false
      #   gateways:
      #   - ${values['global']['helmReleaseNamePrefix']}private-ingress
      #   http:
      #   - match:
      #     - uri:
      #         prefix: /images/
      #     route:
      #     - destination:
      #         host: catalog-qflow-catalog-data.${values['global']['appsNamespace']}.svc.cluster.local
      #         port:
      #           number: 80
      #   - route:
      #     - destination:
      #         host: omnichannel-pos.${values['global']['appsNamespace']}.svc.cluster.local
      #         port:
      #           number: 5010
      openproject:
        enabled: false
        gateways:
          - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
          - route:
              - destination:
                  host: openproject-web.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 8080
      orders-chat:
        enabled: false
        gateways:
          - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
          - route:
              - destination:
                  host: fulfillment-data-chat.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 7001
      prm:
        enabled: false
        gateways:
          - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
          - route:
              - destination:
                  host: partner-management.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 8000
      rbs-ui:
        enabled: false
        gateways:
          - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
          - route:
              - destination:
                  host: rbs-ui-web.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 3000
      recharge-manager:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: recharge-manager-frontend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 7890

      rim:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - match:
          - uri:
              prefix: /loader/
          rewrite:
            uri: /
          route:
          - destination:
              host: resource-inventory-backend-management.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 23000
        - match:
          - uri:
              prefix: /rim-api/
          rewrite:
            uri: /
          route:
          - destination:
              host: rim-wui-frontback.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 9000
        - route:
          - destination:
              host: rim-wui-frontend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8081
      sct:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - match:
          - uri:
              prefix: /images/
          route:
          - destination:
              host: catalog-qflow-catalog-data.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
        - route:
          - destination:
              host: sales-and-care-toolbox-web.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 9000
      tmf-openapi:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: tmf-openapi.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 7777
      tnt:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: tnt-web-tnt-web.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 9001
      zipkin:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: zipkin.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 9411
      # Platform Managed services    
      auth:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}public-ingress
        http:
        - match:
          - uri:
              prefix: /.pomerium/
          route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}pomerium-platform-authenticate.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
        - match:
          - uri:
              prefix: /.well-known/
          route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}pomerium-platform-authenticate.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
        - match:
          - uri:
              prefix: /oauth2/
          route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}pomerium-platform-authenticate.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
        - match:
          - uri:
              prefix: /auth/admin/realms/qvantel
          route:
          - destination:
              host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
        - match:
          - uri:
              prefix: /auth/admin/qvantel/
          route:
          - destination:
              host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
        - match:
          - uri:
              prefix: /auth/admin/serverinfo
          route:
          - destination:
              host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
        - match:
          - uri:
              prefix: /auth/realms/qvantel/
          route:
          - destination:
              host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
        - match:
          - uri:
              prefix: /auth/realms/consumers/
          route:
          - destination:
              host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
        - match:
          - uri:
              prefix: /auth/resources/
          route:
          - destination:
              host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
        - match:
          - uri:
              prefix: /auth/js/
          route:
          - destination:
              host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      artifactory-oss:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: artifactory-oss.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 8082
      artifactory-jcr:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: artifactory-jcr.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 8082             
      consul-ui:
        enabled: false
        pomeriumProtected: true
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}consul-platform-consul-ui.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80      
      grafana:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}monitoring-platform-grafana.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80      
      kafka-ui:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}kafka-platform-kafka-ui.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      keycloak:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      kibana:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              % if addon_operator['logsearchPlatformEnabled'] == 'true':
              host: ${values['global']['helmReleaseNamePrefix']}logsearch-platform-kibana.${values['global']['platformNamespace']}.svc.cluster.local
              % else:
              host: kibana-kb-http.${values['global']['platformNamespace']}.svc.cluster.local
              % endif
              port:
                number: 5601
      logsearch:
        enabled: false
        pomeriumProtected: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              % if addon_operator['logsearchPlatformEnabled'] == 'true':
              host: ${values['global']['helmReleaseNamePrefix']}logsearch-platform.${values['global']['platformNamespace']}.svc.cluster.local
              % else:
              host: logsearch-es-http.${values['global']['platformNamespace']}.svc.cluster.local
              % endif
              port:
                number: 9200
      loki-read:
        enabled: false
        pomeriumProtected: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: loki-read.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 3100
      minio:
        enabled: false
        pomeriumProtected: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}minio-platform.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 9000
      minio-console:
        enabled: false
        pomeriumProtected: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}minio-platform-console.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 9001     
      pmm:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: pmm.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      prometheus:
        enabled: false
        pomeriumProtected: true
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}monitoring-platform-prometheus.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 9090
      rabbitmq:
          enabled: false
          gateways:
            - ${values['global']['helmReleaseNamePrefix']}private-ingress
          tcp:
          - match:
              - port: 61613
            route:
              - destination:
                  host: ${values['global']['helmReleaseNamePrefix']}rabbitmq-platform.${values['global']['platformNamespace']}.svc.cluster.local
                  port:
                    number: 61613
          - match:
              - port: 5672
            route:
              - destination:
                  host: ${values['global']['helmReleaseNamePrefix']}rabbitmq-platform.${values['global']['platformNamespace']}.svc.cluster.local
                  port:
                    number: 5672
          http:
          - match:
              - port: 15674
            route:
              - destination:
                  host: ${values['global']['helmReleaseNamePrefix']}rabbitmq-platform.${values['global']['platformNamespace']}.svc.cluster.local
                  port:
                    number: 15674
      rabbitmq-ui:
          enabled: false
          gateways:
            - ${values['global']['helmReleaseNamePrefix']}private-ingress
          http:
          - route:
            - destination:
                host: ${values['global']['helmReleaseNamePrefix']}rabbitmq-platform.${values['global']['platformNamespace']}.svc.cluster.local
                port:
                  number: 15672
      reaper:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: reaper.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 8080
      sftp:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}integrations-non-http-ingress
        tcp:
        - match:
            - port: 22
          route:
            - destination:
                host: ${values['global']['helmReleaseNamePrefix']}sftpgo-platform.${values['global']['platformNamespace']}.svc.cluster.local
                port:
                  number: 22
      sftp-ui:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}sftpgo-platform.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      vault-ui:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}vault-platform.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 8200
      vector-aggregator-logstash:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}vector-platform-aggregator.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 9000