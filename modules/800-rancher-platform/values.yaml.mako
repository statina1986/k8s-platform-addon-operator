# -- Rancher uses different default namespace from normal platform
rancherPlatformNamespace: cattle-system
# -- We provide multiple versions of the rancher with same module this can be set to supported version
rancherHelmVersion: "2.9.2"
# -- Default rancher configurations
rancherPlatform:
  rancher:
    # -- Hostname is required
    hostname: ""
    # -- Ingress set to false due to Istio being prefered
    ingress:
      enabled: false
    # -- Private Ca set to false by default
    privateCA: false
    % if 'containerRegistryBase' in values['global']:
    rancherImage: ${values['global']['containerRegistryBase']}/rancher/rancher
    % endif
    % if 'containerRegistryBase' in values['global']:
    systemDefaultRegistry: ${values['global']['containerRegistryBase']}
    % endif