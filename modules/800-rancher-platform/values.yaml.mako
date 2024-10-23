rancherPlatformNamespace: cattle-system
rancherHelmVersion: "2.8.1"
rancherPlatform:
  rancher:
    global:
      cattle:
        psp:
          enabled: false
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