mongodbPlatform:
  mongodb:
    global:
      security:
        allowInsecureImages: true
    # -- Deploying as replicaset as opposed to standalone,
    # resulting in an arbiter and two instances, primary
    # and secondary, which may swap.
    architecture: replicaset
    image:
      # In case the registry is pointing towards Platform artifactory,
      # this is a multiarch manifest where amd64 is the official
      # Bitnami image and arm64 is the 7.0.15 release of
      # https://hub.docker.com/r/dlavrenuek/bitnami-mongodb-arm
      #
      # If pointed towards docker.io, only amd64 image will be available
      repository: platform/bitnami-mongodb
      tag: "7.0.15"
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % else:
      registry: platform.artifactory.qvantel.net
      % endif
    % if 'containerRegistryBase' in values['global']:
    tls:
      registry: ${values['global']['containerRegistryBase']}
    % endif
    % if 'containerRegistryBase' in values['global']:
    externalAccess:
      autoDiscovery:
        image:
          registry: ${values['global']['containerRegistryBase']}          
      dnsCheck:
        image:
          registry: ${values['global']['containerRegistryBase']}
    % endif
    % if 'containerRegistryBase' in values['global']:
    volumePermissions:
      image:
        registry: ${values['global']['containerRegistryBase']}
    % endif
    metrics:
      enabled: false
      % if 'containerRegistryBase' in values['global']:
      image:
        registry: ${values['global']['containerRegistryBase']}
      % endif
      