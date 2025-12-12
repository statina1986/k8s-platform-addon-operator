externalDns:
  external-dns:
    namespace: ${values['global']['platformNamespace']}
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % else:
      registry: docker.io
      % endif
      repository: bitnamilegacy/external-dns
      tag: 0.13.4-debian-11-r2
    serviceAccount:
      create: false
      name: platform
    provider: aws
    aws:
      zoneType: public
    sources:
      - crd
      - istio-virtualservice
    txtPrefix: extdns.
    interval: 10m
    annotationFilter: platform.qvantel.com/exclude-from-external-dns notin (true)