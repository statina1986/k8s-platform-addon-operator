externalDns:
  external-dns:
    namespace: ${values['global']['platformNamespace']}
    % if 'containerRegistryBase' in values['global']:
    image:
      registry: ${values['global']['containerRegistryBase']}
    % endif
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