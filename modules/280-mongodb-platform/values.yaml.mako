mongodbPlatform:
  mongodb:
    # -- Deploying as replicaset as opposed to standalone,
    # resulting in an arbiter and two instances, primary
    # and secondary, which may swap.
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
      