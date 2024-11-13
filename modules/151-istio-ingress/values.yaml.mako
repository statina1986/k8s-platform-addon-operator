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
  # -- Configuration for underlying `gateway` helm-chart for Public Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
  publicIngress:
    name: ${values['global']['helmReleaseNamePrefix']}public-ingress
    replicaCount: 3
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
        service.beta.kubernetes.io/aws-load-balancer-type: "external"
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-internal: "false"
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=false
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-public
        % endif
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-public
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
  # -- Configuration for underlying `gateway` helm-chart for Private Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
  privateIngress:
    name: ${values['global']['helmReleaseNamePrefix']}private-ingress
    replicaCount: 3
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
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: "external"
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=false
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-private
        % endif
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-private
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

  # -- Enables Integrations Http Ingress gateway
  integrationsHttpIngressEnabled: false
  # -- Enable full request logging for Integrations Http Ingress gateway
  integrationsHttpIngressLogFullRequest: false
  # -- Enable full response logging for Integrations Http Ingress gateway
  integrationsHttpIngressLogFullResponse: false
  # -- Configure request buffering (in bytes) for Integrations Http Ingress gateway. Set to 0 for disabling buffering.
  integrationsHttpIngressBufferHttpRequestSize: 0
  # -- Configuration for underlying `gateway` helm-chart for Integrations Http Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
  integrationsHttpIngress:
    name: ${values['global']['helmReleaseNamePrefix']}integrations-http-ingress
    replicaCount: 3
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
        service.beta.kubernetes.io/aws-load-balancer-type: "external"
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=false
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-http
        % endif
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-http
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
  # -- Configuration for underlying `gateway` helm-chart for Integrations Non Http Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
  integrationsNonHttpIngress:
    name: ${values['global']['helmReleaseNamePrefix']}integrations-non-http-ingress
    replicaCount: 3
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
        service.beta.kubernetes.io/aws-load-balancer-type: "external"
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=true
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-nonhttp
        % endif
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=${values['global']['helmReleaseNamePrefix']}${values['global']['clusterName']}-i-nonhttp
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
  # -- VirtualServices to be provisioned.
  virtualServices:
    # -- Common annotations for all VirtualServices resources provisioned
    annotations:
    # external-dns.alpha.kubernetes.io/target: my-global-load-balancer.cloud.com
    # -- Common base dns name to be used for all VirtualServices. `host` of VirtualServices will be set to <virtual-service-name>-<dnsBase>. By default value is taken from `global.ingressBaseUrl`
    dnsBase: ${values['global']['ingressBaseUrl']}
    # -- Qvantel applications namespace name. By default value is taken from `global.appsNamespace` and equal to `qvantel`
    appsNamespace: ${values['global']['appsNamespace']}
    # -- Qvantel platform namespace name. By default value is taken from `global.appsNamespace` and equal to `platform`
    platformNamespace: ${values['global']['platformNamespace']}
    # -- List of  `VirtualService` resources to be provisioned. It is a map, so it can be configuration may be inherited/extended in multiple valyes.yaml files.  
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
                  number: 80
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
                prefix: /flow/
            retries:
              attempts: 0
            rewrite:
              uri: /
            route:
            - destination:
                host: mobile-flowable-api.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 80
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
                  number: 80
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
                  host: rbs-ui.${values['global']['appsNamespace']}.svc.cluster.local
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
                number: 80
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
              host: ${values['global']['helmReleaseNamePrefix']}artifactory-oss.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 8082
      artifactory-jcr:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}artifactory-jcr.${values['global']['platformNamespace']}.svc.cluster.local
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
              host: ${values['global']['helmReleaseNamePrefix']}kibana-kb-http.${values['global']['platformNamespace']}.svc.cluster.local
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
              host: ${values['global']['helmReleaseNamePrefix']}logsearch-es-http.${values['global']['platformNamespace']}.svc.cluster.local
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
              host: ${values['global']['helmReleaseNamePrefix']}loki-read.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 3100
      pmm:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}pmm.${values['global']['platformNamespace']}.svc.cluster.local
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
      reaper:
        enabled: false
        gateways:
        - ${values['global']['helmReleaseNamePrefix']}private-ingress
        http:
        - route:
          - destination:
              host: ${values['global']['helmReleaseNamePrefix']}reaper.${values['global']['platformNamespace']}.svc.cluster.local
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
