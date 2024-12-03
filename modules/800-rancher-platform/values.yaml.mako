rancherPlatformNamespace: cattle-system
rancherHelmVersion: "2.9.2"
rancherPlatform:
  rancher:
    hostname: ""
    ingress:
      enabled: false
    privateCA: false
    % if 'containerRegistryBase' in values['global']:
    rancherImage: ${values['global']['containerRegistryBase']}/rancher/rancher
    % endif
    % if 'containerRegistryBase' in values['global']:
    systemDefaultRegistry: ${values['global']['containerRegistryBase']}
    % endif