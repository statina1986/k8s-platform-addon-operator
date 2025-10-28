metallbPlatform:
  metallb:
    imagePullSecrets: []
    nameOverride: ""
    fullnameOverride: ""
    loadBalancerClass: ""
    controller:
      image:
        % if 'containerRegistryBase' in values['global']:
        repository: ${values['global']['containerRegistryBase']}/metallb/controller
        % endif
    speaker:
      image:
        % if 'containerRegistryBase' in values['global']:
        repository: ${values['global']['containerRegistryBase']}/metallb/speaker
        % endif
      frr:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/frrouting/frr
          % endif