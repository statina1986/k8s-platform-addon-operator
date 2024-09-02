externalDns:
  external-dns:
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % endif
    serviceAccount:
      create: false
      name: platform
    provider: aws
    aws:
      zoneType: public
    sources:
      - service
      - ingress
      - istio-gateway
      - istio-virtualservice
    txtPrefix: extdns.
    interval: 10m
    annotationFilter: platform.qvantel.com/exclude-from-external-dns notin (true)