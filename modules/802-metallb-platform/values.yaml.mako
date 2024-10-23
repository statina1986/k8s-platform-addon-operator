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
        tag: v0.14.8
    speaker:
      image:
        % if 'containerRegistryBase' in values['global']:
        repository: ${values['global']['containerRegistryBase']}/metallb/speaker
        % endif
        tag: v0.14.8
      frr:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/frrouting/frr
          % endif
          tag: 9.1.0