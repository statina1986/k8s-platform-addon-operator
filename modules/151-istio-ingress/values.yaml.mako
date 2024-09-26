istioIngress:
  pomeriumEnabled: false
  # Public Ingress
  publicIngressEnabled: false
  publicIngressLogFullRequest: false
  publicIngressLogFullResponse: false
  publicIngressBufferHttpRequestSize: 0
  publicIngress:
    name: public-ingress
    replicaCount: 3
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            istio: public-ingress
    autoscaling:
      enabled: true
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
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['clusterName']}-i-public
        % endif
  publicIngressGateways:
  - name: public-ingress
    spec:
      selector:
        istio: public-ingress
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
          # Private Ingress
  privateIngressEnabled: false
  privateIngressLogFullRequest: false
  privateIngressLogFullResponse: false
  privateIngressBufferHttpRequestSize: 0
  privateIngress:
    name: private-ingress
    replicaCount: 3
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            istio: private-ingress
    autoscaling:
      enabled: true
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
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['clusterName']}-i-private
        % endif
  privateIngressGateways:
  - name: private-ingress
    spec:
      selector:
        istio: private-ingress
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
          # IntegrationsHttp Ingress
  integrationsHttpIngressEnabled: false
  integrationsHttpIngressLogFullRequest: false
  integrationsHttpIngressLogFullResponse: false
  integrationsHttpIngressBufferHttpRequestSize: 0
  integrationsHttpIngress:
    name: integrations-http-ingress
    replicaCount: 3
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            istio: integrations-http-ingress
    autoscaling:
      enabled: true
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
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['clusterName']}-i-http
        % endif
  integrationsHttpIngressGateways:
  - name: integrations-http-ingress
    spec:
      selector:
        istio: integrations-http-ingress
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
          # IntegrationsNonHttp Ingress
  integrationsNonHttpIngressEnabled: false
  integrationsNonHttpIngressLogFullRequest: false
  integrationsNonHttpIngressLogFullResponse: false
  integrationsNonHttpIngressBufferHttpRequestSize: 0
  integrationsNonHttpIngress:
    name: integrations-non-http-ingress
    replicaCount: 3
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            istio: integrations-non-http-ingress
    autoscaling:
      enabled: true
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
        % if 'clusterName' in values['global']:
        service.beta.kubernetes.io/aws-load-balancer-name: ${values['global']['clusterName']}-i-nonhttp
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
  integrationsNonHttpIngressGateways:
  - name: integrations-non-http-ingress
    spec:
      selector:
        istio: integrations-non-http-ingress
      servers:
      - hosts:
        - '*'
        port:
          name: sftp
          number: 22
          protocol: TCP
  virtualServices:
    annotations:
    # external-dns.alpha.kubernetes.io/target: my-global-load-balancer.cloud.com
    dnsBase: ${values['global']['ingressBaseUrl']}
    appsNamespace: ${values['global']['appsNamespace']}
    platformNamespace: ${values['global']['platformNamespace']}
    instances: 
      # Product managed services    
      address-manager:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: addresses.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8000
      billing:
        enabled: false
        gateways:
          - private-ingress
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
        - private-ingress
        http:
        - route:
          - destination:
              host: bssapi-aggregator.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
      bssapi-docs:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: bssapi-documentation-service.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8010
      bssapi-explorer:
        enabled: false
        gateways:
        - private-ingress
        http:
          - route:
            - destination:
                host: bssapi-explorer.${values['global']['appsNamespace']}.svc.cluster.local
                port:
                  number: 8080
      b2b-sales-tool:
        enabled: false
        gateways:
        - private-ingress
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
        - private-ingress
        http:
        - route:
          - destination:
              host: b2b-flex-ecare-web.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 3000
      b2c-flex-ecare:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: b2c-flex-ecare-web.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 3000
      case-admin:
        enabled: false
        gateways:
        - private-ingress
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
        - private-ingress
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
        - private-ingress
        http:
        - route:
          - destination:
              host: catalog-qflow-catalog-deployer.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
      catalog-designer:
        enabled: false
        gateways:
        - private-ingress
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
        - private-ingress
        http:
        - route:
          - destination:
              host: cdt-frontend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 3001
      document-manager:
        enabled: false
        gateways:
        - private-ingress
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
        - private-ingress
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
        - private-ingress
        http:
        - route:
          - destination:
              host: flex-admin.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 21080
      flex-app-store:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: flex-app-store.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 21090
      flex-content-provider:
        enabled: false
        gateways:
          - private-ingress
        http:
          - retries:
              attempts: 0
            route:
              - destination:
                  host: flex-content-provider.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 21210
      flex-bpmn-executor:
        enabled: false
        gateways:
          - private-ingress
        http:
          - retries:
              attempts: 0
            route:
              - destination:
                  host: flex-bpmn-executor.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 21010
      graphql:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: graphql-graphql-bssapi.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8180      
      knowledge:
        enabled: false
        gateways:
        - private-ingress
        http:
        - match:
          - uri:
              exact: /
          redirect:
            uri: /knowledge_wiki/
        - route:
          - destination:
              host: knowledge-wiki.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8080
      kpitool:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: kpi-tool-front.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 4458
      mapp:
        enabled: false
        gateways:
          - public-ingress
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
        - private-ingress
        http:
        - route:
          - destination:
              host: message-manager-wui.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 3003
      mobile-ui-builder:
        enabled: false
        gateways:
          - private-ingress
        http:
          - retries:
              attempts: 0
            route:
              - destination:
                  host: mobile-ui-builder.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 21080
      mockbank:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: omnichannel-bank.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 3500
      mockoss:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: mockoss.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8000
      pcb:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: pcb.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 8095
      pos:
        enabled: false
        gateways:
        - private-ingress
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
              host: omnichannel-pos.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 5010
      rbs-ui:
        enabled: false
        gateways:
          - private-ingress
        http:
          - route:
              - destination:
                  host: rbs-ui.${values['global']['appsNamespace']}.svc.cluster.local
                  port:
                    number: 3000
      recharge-manager:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: recharge-manager-frontend.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 7890

      rim:
        enabled: false
        gateways:
        - private-ingress
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
        - private-ingress
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
        - private-ingress
        http:
        - route:
          - destination:
              host: tmf-openapi.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 7777
      tnt:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: tnt-web-tnt-web.${values['global']['appsNamespace']}.svc.cluster.local
              port:
                number: 9001
      zipkin:
        enabled: false
        gateways:
        - private-ingress
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
        - public-ingress
        http:
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
        - private-ingress
        http:
        - route:
          - destination:
              host: artifactory-oss.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 8082
      artifactory-jcr:
        enabled: false
        gateways:
        - private-ingress
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
        - private-ingress
        http:
        - route:
          - destination:
              host: consul-platform-consul-ui.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80      
      grafana:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: monitoring-platform-grafana.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      prometheus:
        enabled: false
        pomeriumProtected: true
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: monitoring-platform-kube-p-prometheus.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 9090
      kafka-ui:
        enabled: false
        pomeriumProtected: true
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: kafka-platform-kafka-ui.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      keycloak:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: qvaa-proxy-80.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      reaper:
        enabled: true
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: reaper.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 8080
      kibana:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: kibana-kb-http.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 5601
      logsearch:
        enabled: false
        pomeriumProtected: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: logsearch-es-http.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 9200
      loki-read:
        enabled: false
        pomeriumProtected: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: loki-read.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 3100
      pmm:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: pmm.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      sftp:
        enabled: false
        gateways:
        - integrations-non-http-ingress
        tcp:
        - match:
            - port: 22
          route:
            - destination:
                host: sftpgo-platform.${values['global']['platformNamespace']}.svc.cluster.local
                port:
                  number: 22
      sftp-ui:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: sftpgo-platform.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 80
      vault-ui:
        enabled: false
        gateways:
        - private-ingress
        http:
        - route:
          - destination:
              host: vault-platform.${values['global']['platformNamespace']}.svc.cluster.local
              port:
                number: 8200
