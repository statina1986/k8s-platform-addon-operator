# istioPlatformNamespace: istio-system
pomeriumPlatform:
  pomerium:
    baseUrl: ${values['global']['ingressBaseUrl']}
    image:
      repository: ${values['pomeriumPlatform']['images']['pomerium']['registry']}/${values['pomeriumPlatform']['images']['pomerium']['repository']}
      tag: ${values['pomeriumPlatform']['images']['pomerium']['tag']}
    ingress:
      enabled: false
    ingressController:
      image:
        repository: ${values['pomeriumPlatform']['images']['ingressController']['registry']}/${values['pomeriumPlatform']['images']['ingressController']['repository']}
        tag: ${values['pomeriumPlatform']['images']['ingressController']['tag']}
    extraVolumeMounts:
      - name: trusted-ca-tls
        mountPath: /etc/ssl/certs
    extraVolumes:
      - name: trusted-ca-tls
        secret:
          defaultMode: 420
          optional: true
          secretName: qvantel-root-ca
    proxy:
      authenticateServiceUrl: https://auth-${values['global']['ingressBaseUrl']}
    config:
      extraOpts:
        log_level: info
      existingSharedSecret: pomerium-platform-shared
      extraSharedSecretLabels: []
      insecure: true
      insecureProxy: true
      generateTLS: false
      generateSigningKey: true
      routes: |
        - from: https://kafka-ui-${values['global']['ingressBaseUrl']}
          to: http://kafka-ui.platform.svc.cluster.local:8080
          timeout: 30s
          policy:
            - allow:
                and:
                  - claim/realm_access.roles: kafka-readonly
                  - http_method:
                      is: GET
            - allow:
                and:
                  - claim/realm_access.roles: kafka-admins
        - from: https://prometheus-${values['global']['ingressBaseUrl']}
          to: http://monitoring-platform-kube-p-prometheus.platform.svc.cluster.local:9090
          timeout: 30s
          policy:
            - allow:
                and:
                  - claim/realm_access.roles: prometheus-readonly
                  - http_method:
                      is: GET
            - allow:
                and:
                  - claim/realm_access.roles: prometheus-admins
        - from: https://consul-ui-${values['global']['ingressBaseUrl']}
          to: http://consul-platform-consul-ui.platform.svc.cluster.local:80
          timeout: 30s
          policy:
            - allow:
                and:
                  - claim/realm_access.roles: consul-readonly
                  - http_method:
                      is: GET
            - allow:
                and:
                  - claim/realm_access.roles: consul-admins
        {{ .Values.additionalRoutes}}
    authenticate:
      idp:
        provider: oidc
        url: https://auth-${values['global']['ingressBaseUrl']}/auth/realms/qvantel
        clientID: "pomerium"
