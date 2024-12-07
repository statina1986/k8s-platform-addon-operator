perconaPmmPlatform:
  pmm:
    % if 'containerRegistryBase' in values['global']:
    image:
      repository: ${values['global']['containerRegistryBase']}/percona/pmm-server
    % endif
    
    service:
      name: pmm
      type: ClusterIP
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"