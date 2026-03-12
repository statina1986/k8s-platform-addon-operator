istioIngress:
  # -- Enables Pomerium Authorization proxy. This will affect only VirtualServices which have `pomeriumProtected: true` attributes
  pomeriumEnabled: false
  # -- Variable to enable DNA program specific values and configurations.
  dnaIstioProfile: false
  # -- Variable to enable external-VM connections which is based on Istio-proxy installation.
  externalIstioProxy: false

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
      % if not values.get("istioIngress", {}).get("dnaIstioProfile"):
      % if values.get("istioIngress", {}).get("virtualServices", {}).get("instances", {}).get("rabbitmq", False):
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
      % endif
      % if values.get("istioIngress", {}).get("virtualServices", {}).get("instances", {}).get("vector-aggregator-logstash", False):
      - name: vector-logs
        port: 9000
        protocol: TCP
        targetPort: 9000
      % endif
      % endif
      % if values.get("istioIngress", {}).get("externalIstioProxy", False):
      - name: tls
        port: 15443
        targetPort: 15443
      - name: tls-istiod
        port: 15012
        targetPort: 15012
      - name: tls-webhook
        port: 15017
        targetPort: 15017
      % endif
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
        % if values.get("istioIngress", {}).get("dnaIstioProfile", False):
        tls:
          httpsRedirect: true
        % endif
      - hosts:
        - '*'
        port:
          name: https
          number: 443
          protocol: HTTPS
        tls:
          mode: SIMPLE
          % if values.get("istioIngress", {}).get("dnaIstioProfile", False):
          credentialName: ingress-cert-k8s-qvantel-net
          maxProtocolVersion: TLSV1_3
          minProtocolVersion: TLSV1_2
          % else:
          credentialName: qvantel-wildcard
          % endif
      % if not values.get("istioIngress", {}).get("dnaIstioProfile"):
      % if values.get("istioIngress", {}).get("virtualServices", {}).get("instances", {}).get("rabbitmq", False):
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
      % endif
      % if values.get("istioIngress", {}).get("virtualServices", {}).get("instances", {}).get("vector-aggregator-logstash", False):
      - hosts:
        - '*'
        port:
          name: vector-logs
          number: 9000
          protocol: TCP
      % endif
      % endif
  % if values.get("istioIngress", {}).get("externalIstioProxy", False):
  - name: ${values['global']['helmReleaseNamePrefix']}istio-eastwestgateway
    spec:
      selector:
        istio: ${values['global']['helmReleaseNamePrefix']}private-ingress
      servers:
        - hosts:
            - '*'
          port:
            name: tls-istiod
            number: 15012
            protocol: tls
          tls:
            mode: PASSTHROUGH
        - hosts:
            - '*'
          port:
            name: tls-istiodwebhook
            number: 15017
            protocol: tls
          tls:
            mode: PASSTHROUGH
  % endif

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
      ## DNA specific
      % if values.get("istioIngress", {}).get("dnaIstioProfile", False):
      - name: bss-integrator-hybris-shop-api
        port: 2035
        targetPort: 2035
      - name: bss-integrator-hybris-inventory-api
        port: 2045
        targetPort: 2045
      - name: bss-integrator-mobile-id-api-v1
        port: 2050
        targetPort: 2050
      - name: bss-integrator-mobile-id-api-v2
        port: 2055
        targetPort: 2055
      - name: bss-integrator-pyprov-network-listener-api
        port: 2065
        targetPort: 2065
      - name: bss-integrator-hybris-gatekeeper-api
        port: 2075
        targetPort: 2075
      - name: bss-integrator-crm-gatekeeper-api
        port: 2080
        targetPort: 2080
      - name: bss-integrator-rbs-gatekeeper-api
        port: 2085
        targetPort: 2085
      - name: bss-integrator-dil-listener-api
        port: 2095
        targetPort: 2095
      - name: bss-integrator-bssapi-aggregator
        port: 3000
        targetPort: 3000
      - name: bss-integrator-orders-event-receiver
        port: 3010
        targetPort: 3010
      - name: bss-integrator-kafka-bootstrap
        port: 9093
        targetPort: 9093
      - name: bss-integrator-kafka-broker1
        port: 9094
        targetPort: 9094
      % if values.get('global', {}).get('configurationProfile') in {'prod', 'perf'}:
      - name: bss-integrator-kafka-broker2
        port: 9095
        targetPort: 9095
      - name: bss-integrator-kafka-broker3
        port: 9096
        targetPort: 9096
      % endif
      - name: bss-integrator-navision-api
        port: 10000
        targetPort: 10000
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
        % if values.get("istioIngress", {}).get("dnaIstioProfile", False):
        tls:
          httpsRedirect: true
        % endif
      - hosts:
        - '*'
        port:
          name: https
          number: 443
          protocol: HTTPS
        tls:
          mode: SIMPLE
          % if values.get("istioIngress", {}).get("dnaIstioProfile", False):
          credentialName: ingress-cert-dna
          maxProtocolVersion: TLSV1_3
          minProtocolVersion: TLSV1_2
          % else:
          credentialName: qvantel-wildcard
          % endif
      ## DNA specific
      % if values.get("istioIngress", {}).get("dnaIstioProfile", False):
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-hybris-shop-api
          number: 2035
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-hybris-inventory-api
          number: 2045
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-mobile-id-api-v1
          number: 2050
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-mobile-id-api-v2
          number: 2055
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-pyprov-network-listener-api
          number: 2065
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-hybris-gatekeeper-api
          number: 2075
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-crm-gatekeeper-api
          number: 2080
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-rbs-gatekeeper-api
          number: 2085
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-dil-listener-api
          number: 2095
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-bssapi-aggregator
          number: 3000
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-orders-event-receiver
          number: 3010
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-navision-api
          number: 10000
          protocol: HTTPS
        tls:
          credentialName: ingress-cert-dna
          mode: SIMPLE
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-kafka-bootstrap
          number: 9093
          protocol: TLS
        tls:
          mode: PASSTHROUGH
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-kafka-broker1
          number: 9094
          protocol: TLS
        tls:
          mode: PASSTHROUGH
      % if values.get('global', {}).get('configurationProfile') in {'prod', 'perf'}:
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-kafka-broker2
          number: 9095
          protocol: TLS
        tls:
          mode: PASSTHROUGH
      - hosts:
          - '*'
        port:
          name: public-bss-integrator-kafka-broker3
          number: 9096
          protocol: TLS
        tls:
          mode: PASSTHROUGH
      % endif
      % endif

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
  # -- EnvoyFilters to be provisioned.
  # @default -- see values.yaml.mako
  envoyFilters:
    # -- Common annotations for all EnvoyFilters resources provisioned
    annotations:
    # -- List of `EnvoyFilter` resources to be provisioned. It is a map, so its' configuration can be inherited/extended in multiple valyes.yaml files. Note that `configPatches` under spec of individual filter is a list.
    # @default -- see values.yaml.mako  
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
    # -- List of multiInstances `EnvoyFilter` resources to be provisioned. Meant for large and repetitive `EnvoyFilter`
    # @default -- see values.yaml.mako  
    multiInstances:
      bss-integrator-ingress-gateway-opts:
        enabled: false
        variables:
          ports:
          - 2035
          - 2045
          - 2050
          - 2055
          - 2065
          - 2075
          - 2085
          - 2080
          - 2095
          - 3000
          - 3010
          - 9093
          - 9094
          - 9095
          - 9096
          - 10000
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
  # -- DestinationRules to be provisioned.
  # @default -- see values.yaml.mako
  destinationRules:
    # -- Common annotations for all EnvoyFilters resources provisioned
    annotations:
    # -- List of  `DestinationRule` resources to be provisioned. It is a map, so its' configuration can be inherited/extended in multiple valyes.yaml files.
    # @default -- see values.yaml.mako  
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
    # -- List of multiInstances `DestinationRule` resources to be provisioned. Meant for repetitive `DestinationRules`. Individual entries can be disabled by setting them as `null`
    # @default -- see values.yaml.mako  
    multipleInstances:
      dna-destinationrules:
        enabled: false
        entries:
          # RBS-related
          rbs-master-xmlrpc-dr:
            host: rbs-master-xmlrpc.qvantel.svc.cluster.local
          # Qvantel namespace related
          activation-frontend-dr:
            host: activation-frontend.qvantel.svc.cluster.local
          audit-admin-dr:
            host: audit-admin.qvantel.svc.cluster.local
          billingui-backend-dr:
            host: billingui-backend.qvantel.svc.cluster.local
          billingui-frontend-log-proxy-dr:
            host: billingui-frontend-log-proxy-8181.qvantel.svc.cluster.local
          billingui-frontend-dr:
            host: billingui-frontend.qvantel.svc.cluster.local
          crm-gatekeeper-api-dr:
            host: crm-gatekeeper-api.qvantel.svc.cluster.local
          dnapy-proq-dr:
            host: dnapy-web-proq.qvantel.svc.cluster.local
          dnapy-navision-api-dr:
            host: dnapy-soap-navision.qvantel.svc.cluster.local
          dnapy-rest-dil-listener-dr:
            host: dnapy-rest-dil-listener.qvantel.svc.cluster.local
          dnapy-mobile-id-api-v1-dr:
            host: dnapy-api-mobile-id.qvantel.svc.cluster.local
          dnapy-robot-dr:
            host: dnapy-web-robot.qvantel.svc.cluster.local
          dnapy-extcc-dr:
            host: dnapy-web-extcc.qvantel.svc.cluster.local
          dnapy-frontback-activation-dr:
            host: dnapy-frontback-activation.qvantel.svc.cluster.local
          fake-dil-dr:
            host: fake-dil-admin.qvantel.svc.cluster.local
          hybris-inventory-api-dr:
            host: hybris-inventory-api-8080.qvantel.svc.cluster.local
          hybris-shop-api-dr:
            host: dnapy-rest-bssapi-shop.qvantel.svc.cluster.local
          hybris-gatekeeper-api-dr:
            host: hybris-gatekeeper-api.qvantel.svc.cluster.local
          kafka-admin-web-dr:
            host: kafka-admin-web.qvantel.svc.cluster.local
          mobile-id-api-dr:
            host: mobile-id-app-api.qvantel.svc.cluster.local
          operational-index-dr:
            host: operational-index-8080.qvantel.svc.cluster.local
          peon-admin-frontend-dr:
            host: peon-admin-frontend.qvantel.svc.cluster.local
          peon-admin-backend-dr:
            host: peon-admin-backend-8080.qvantel.svc.cluster.local
          product-catalog-visualizer-dr:
            host: product-catalog-visualizer.qvantel.svc.cluster.local
          pyprov-admin-dr:
            host: pyprov-admin.qvantel.svc.cluster.local
          pyprov-network-listener-dr:
            host: pyprov-network-listener-8080.qvantel.svc.cluster.local
          rbs-gatekeeper-admin-dr:
            host: rbs-gatekeeper-admin.qvantel.svc.cluster.local
          rbs-gatekeeper-api-dr:
            host: rbs-gatekeeper-api.qvantel.svc.cluster.local
          salestool-backend-telesales-dr:
            host: salestool-backend-telesales.qvantel.svc.cluster.local
          salestool-frontend-telesales-dr:
            host: salestool-frontend-telesales.qvantel.svc.cluster.local
          salestool-backend-pos-dr:
            host: salestool-backend-pos.qvantel.svc.cluster.local
          salestool-frontend-pos-dr:
            host: salestool-frontend-pos.qvantel.svc.cluster.local
          # qrp namespace related
          bssapi-aggregator-dr:
            host: bssapi-aggregator.qrp.svc.cluster.local
          bssapi-explorer-dr:
            host: bssapi-explorer.qrp.svc.cluster.local
          bssapi-documentation-dr:
            host: bssapi-documentation-service.qrp.svc.cluster.local
          catalog-deployer-dr:
            host: qflow-catalog-deployer.qrp.svc.cluster.local
          catalog-designer-dr:
            host: qflow-product-catalog-designer-9003.qrp.svc.cluster.local
          flex-admin-dr:
            host: flex-admin.qrp.svc.cluster.local
          flex-app-store-dr:
            host: flex-app-store.qrp.svc.cluster.local
          orders-event-receiver-dr:
            host: orders-event-receiver.qrp.svc.cluster.local
          zipkin-dr:
            host: dna-zipkin.qrp.svc.cluster.local
          # platform related
          vault-ui-dr:
            host: vault.platform.svc.cluster.local
          keycloak-auth-dr:
            host: qvaa-proxy-80.platform.svc.cluster.local
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
        # -- Example of ACME Resolver settings, can be set under any VirtualService
        # -- To enable path in VS to resolver service and deploy the service, see [acme-solver-service](templates/acme-solver-service.yaml)
        acmeResolver: false
        # -- What selector to add to the ACME solver service, should match what is configured under cert issuer, see: https://cert-manager.io/v1.1-docs/configuration/acme/http01/#podtemplate
        acmeSolverSelector: ""
        # -- Override servicename of ACME solver service, by default it is {{ virtualservice-name }}-acme-solver
        acmeSolverHost: ""
        # -- Override port of ACME solver service, by default it is 8089
        acmeSolverPort: 8089
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
          - ${values['global']['helmReleaseNamePrefix']}private-ingress
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
      ## DNA Program/Product managed services
      aktivoi:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - name: "activation-frontback-api-route"
          match:
            - uri:
                prefix: "/api"
            - uri:
                prefix: "/tupas"
            - uri:
                prefix: "/remember_company_id"
            - uri:
                prefix: "/saml2"
            - uri:
                prefix: "/static"
            - uri:
                prefix: "/oidc"
          route:
            - destination:
                host: dnapy-frontback-activation.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        - name: "activation-frontend-route"
          route:
          - destination:
              host: activation-frontend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 80
      billing:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - name: "billingui-backend-route"
          match:
            - uri:
                prefix: "/api/"
            - uri:
                prefix: "/ws/"
            - uri:
                prefix: "/sso/"
          route:
            - destination:
                host: billingui-backend.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        - name: "billingui-frontend-log-proxy-route"
          match:
            - uri:
                prefix: "/logging/"
          route:
            - destination:
                host: billingui-frontend-log-proxy-8181.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8181
        - name: "billingui-frontend-route"
          route:
          - destination:
              host: billingui-frontend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 80
      aspaauvo:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - name: "dnapy-extcc-route"
          route:
            - destination:
                host: dnapy-web-extcc.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
      robot:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - name: "dnapy-robot-route"
          route:
            - destination:
                host: dnapy-web-robot.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
      aspa:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - name: "dnapy-proq-static-route"
          match:
            - uri:
                prefix: "/static"
          headers:
            response:
              set:
                X-Frame-Options: "DENY"
                X-XSS-Protection: "1"
                X-Content-Type-Options: "nosniff"
                Cache-Control: "max-age=86400"
                Strict-Transport-Security: "max-age=1500"
          route:
            - destination:
                host: dnapy-web-proq.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        - name: "dnapy-proq-route"
          route:
            - destination:
                host: dnapy-web-proq.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
      operational:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        ### KEYCLOAK ###
        - name: "keycloak-auth-route"
          match:
            - uri:
                prefix: "/auth/"
          route:
            - destination:
                host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
                port:
                  number: 80
        ### AUDIT ADMIN ###
        - name: "operational-audit-admin-route"
          match:
            - uri:
                prefix: "/audit/"
          route:
            - destination:
                host: audit-admin.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        ### FAKE DIL ###
        - name: "fake-dil-admin-route"
          match:
            - uri:
                prefix: "/fake_dil/"
          route:
            - destination:
                host: fake-dil-admin.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        ### PEON ADMIN ###
        - name: "operational-peon-admin-backend-route"
          match:
            - uri:
                prefix: "/peon/api"
            - uri:
                prefix: "/peon/oidc"
          route:
            - destination:
                host: peon-admin-backend-8080.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        - name: "operational-peon-admin-frontend-route"
          match:
            - uri:
                prefix: "/peon/"
          route:
            - destination:
                host: peon-admin-frontend.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 80
        ### PYPROV ADMIN ###
        - name: "operational-pyprov-admin-route"
          match:
            - uri:
                prefix: "/pyprov/"
          route:
            - destination:
                host: pyprov-admin.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        ### RBS GATEKEEPER ADMIN ###
        - name: "operational-rbs-gatekeeper-admin-route"
          match:
            - uri:
                prefix: "/rbs-gatekeeper"
          route:
            - destination:
                host: rbs-gatekeeper-admin.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        ### RBS TASKER ADMIN ###
        - name: "operational-rbs-tasker-admin-backend-route"
          match:
            - uri:
                prefix: "/rbs_tasker/api"
            - uri:
                prefix: "/rbs_tasker/oidc"
          route:
            - destination:
                host: rbs-tasker-admin-backend-8080.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        - name: "operational-rbs-tasker-admin-frontend-route"
          match:
            - uri:
                prefix: "/rbs_tasker/"
          route:
            - destination:
                host: rbs-tasker-admin-frontend.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 80
        ### KAFKA ADMIN ###
        - name: "operational-kafka-admin-route"
          match:
            - uri:
                prefix: "/kafka/"
          route:
            - destination:
                host: kafka-admin-web.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
          ### PRODUCT CATALOG VISUALIZER ###
        - name: "product-catalog-visualizer-route"
          match:
            - uri:
                prefix: "/product-catalog-visualizer/"
          route:
            - destination:
                host: product-catalog-visualizer.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        ### INDEX PAGE ###
        - name: "operational-index-page-route"
          match:
            - uri:
                prefix: "/"
          route:
            - destination:
                host: operational-index-8080.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
      pos:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - name: "salestool-backend-pos-route"
          match:
            - uri:
                prefix: "/api"
            - uri:
                prefix: "/sso"
          route:
            - destination:
                host: salestool-backend-pos.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        - name: "salestool-frontend-pos-route"
          route:
          - destination:
              host: salestool-frontend-pos.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 80
      telesales:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - name: "salestool-backend-telesales-route"
          match:
            - uri:
                prefix: "/api"
            - uri:
                prefix: "/sso"
          route:
            - destination:
                host: salestool-backend-telesales.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
        - name: "salestool-frontend-telesales-route"
          route:
          - destination:
              host: salestool-frontend-telesales.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 80
      robot:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - name: "dnapy-robot-route"
          route:
            - destination:
                host: dnapy-web-robot.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
      # This is DNA specific
      bss-integrator:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - match:
          - port: 2035
            uri:
              prefix: "/api/"
          rewrite:
            uri: "/"
          route:
            - destination:
                host: dnapy-rest-bssapi-shop.qvantel.svc.cluster.local
                port:
                  number: 8080
        - match:
          - port: 2045
          route:
          - destination:
              host: hybris-inventory-api-8080.qvantel.svc.cluster.local
              port:
                number: 8080
        - match:
          - port: 2050
          route:
            - destination:
                host: dnapy-api-mobile-id.qvantel.svc.cluster.local
                port:
                  number: 8080
        - match:
          - port: 2055
          route:
            - destination:
                host: mobile-id-app-api.qvantel.svc.cluster.local
                port:
                  number: 8080
        - match:
          - port: 2065
          route:
          - destination:
              host: pyprov-network-listener-8080.qvantel.svc.cluster.local
              port:
                number: 8080
        - match:
          - port: 2075
          route:
          - destination:
              host: hybris-gatekeeper-api.qvantel.svc.cluster.local
              port:
                number: 8080
        - match:
          - port: 2080
          route:
          - destination:
              host: crm-gatekeeper-api.qvantel.svc.cluster.local
              port:
                number: 8080
        - match:
          - port: 2085
          route:
          - destination:
              host: rbs-gatekeeper-api.qvantel.svc.cluster.local
              port:
                number: 8080
        - match:
          - port: 2095
          route:
            - destination:
                host: dnapy-rest-dil-listener.qvantel.svc.cluster.local
                port:
                  number: 8080
        - match:
          - port: 3000
          route:
          - destination:
              host: bssapi-aggregator.qrp.svc.cluster.local
              port:
                number: 8080
        - name: "bss-integrator-orders-event-receiver-route"
          match:
          - port: 3010
          route:
          - destination:
              host: orders-event-receiver.qrp.svc.cluster.local
              port:
                number: 21060
        - name: "bss-integrator-orders-event-receiver-health-route"
          match:
          - port: 3010
            uri:
              prefix: "/health"
          route:
          - destination:
              host: orders-event-receiver-management.qrp.svc.cluster.local
              port:
                number: 21061
        - match:
          - port: 10000
          route:
            - destination:
                host: dnapy-soap-navision.qvantel.svc.cluster.local
                port:
                  number: 8080
        tls:
        - match:
          - port: 9093
            sniHosts:
            - make-this-be-same-as-vshost
          route:
            - destination:
                host: kafka-cluster-kafka-external-bootstrap.${values['global']['platformNamespace']}.svc.cluster.local
                port:
                  number: 9093
        - match:
          - port: 9094
            sniHosts:
            - make-this-be-same-as-vshost
          route:
            - destination:
                host: kafka-cluster-kafka-cluster-kafka-external-1.${values['global']['platformNamespace']}.svc.cluster.local
                port:
                  number: 9093
        - match:
          - port: 9095
            sniHosts:
            - make-this-be-same-as-vshost
          route:
            - destination:
                host: kafka-cluster-kafka-cluster-kafka-external-2.${values['global']['platformNamespace']}.svc.cluster.local
                port:
                  number: 9093
        - match:
          - port: 9096
            sniHosts:
            - make-this-be-same-as-vshost
          route:
            - destination:
                host: kafka-cluster-kafka-cluster-kafka-external-3.${values['global']['platformNamespace']}.svc.cluster.local
                port:
                  number: 9093
      rabbitmq-hpd:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - name: "rabbitmq-hpd-admin-route"
          route:
            - destination:
                host: hpd-rabbitmq.${values['global']['platformNamespace']}.svc.cluster.local
                port:
                  number: 15672
      sentry:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: dna-sentry-nginx.${values['global']['sentryNamespace']}.svc.cluster.local
              port:
                number: 80
      # Platform Managed services
      istiod:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}istio-eastwestgateway
        hosts:
        - "*"
        tls:
        - match:
          - port: 15012
            sniHosts:
            - "*"
          route:
          - destination:
              host: istiod.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 15012
        - match:
          - port: 15017
            sniHosts:
            - "*"
          route:
          - destination:
              host: istiod.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 443
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
              regex: ^/auth/realms/(bss|consumers|partners|platform|qvantel)
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
        tcp:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}vector-platform-aggregator.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 9000