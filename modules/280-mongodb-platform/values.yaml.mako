mongodbPlatform:
  mongodb:
    architecture: replicaset
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % endif
    tls:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % endif
    externalAccess:
      autoDiscovery:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
      dnsCheck:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
    volumePermissions:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
    metrics:
      enabled: false
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
      