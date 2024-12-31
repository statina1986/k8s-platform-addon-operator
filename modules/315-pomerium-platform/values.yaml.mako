# istioPlatformNamespace: istio-system
pomeriumPlatform:
  pomerium:
    baseUrl: ${values['global']['ingressBaseUrl']}
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/pomerium/pomerium
      % endif
    ingress:
      enabled: false
    ingressController:
      image:
        % if 'containerRegistryBase' in values['global']:
        repository: ${values['global']['containerRegistryBase']}/pomerium/ingress-controller
        % endif
    proxy:
      authenticateServiceUrl: https://auth${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}
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
        - from: https://prometheus${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}
          to: http://${values['global']['helmReleaseNamePrefix']}monitoring-platform-prometheus.${values['global']['platformNamespace']}.svc.cluster.local:9090
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
        - from: https://consul-ui${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}
          to: http://${values['global']['helmReleaseNamePrefix']}consul-platform-consul-ui.${values['global']['platformNamespace']}.svc.cluster.local:80
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
        url: https://auth${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}/auth/realms/qvantel
        clientID: "pomerium"
