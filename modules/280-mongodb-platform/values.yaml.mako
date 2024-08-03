mongodbPlatform:
  mongodb:
    architecture: replicaset
    image:
      registry: ${values['global']['containerRegistryBase']}
    tls:
      registry: ${values['global']['containerRegistryBase']}
    externalAccess:
      autoDiscovery:
        image:
          registry: ${values['global']['containerRegistryBase']}
      dnsCheck:
        image:
          registry: ${values['global']['containerRegistryBase']}
    volumePermissions:
      image:
        registry: ${values['global']['containerRegistryBase']}
    metrics:
      enabled: false
      image:
        registry: ${values['global']['containerRegistryBase']}
      