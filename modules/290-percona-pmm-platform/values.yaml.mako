perconaPmmPlatform:
  pmm:
    % if 'containerRegistryBase' in values['global']:
    image:
      repository: ${values['global']['containerRegistryBase']}/percona/pmm-server
    % endif
    
    service:
      name: pmm
      type: ClusterIP