# -- Default configurations for metric platform
metricsPlatform:
  metrics-server:
    % if 'containerRegistryBase' in values['global']:
    image:
      repository: ${values['global']['containerRegistryBase']}/metrics-server/metrics-server
    % endif
    addonResizer:
      % if 'containerRegistryBase' in values['global']:
      image:
        repository: ${values['global']['containerRegistryBase']}/autoscaling/addon-resizer
      % else:
      image:
        repository: registry.k8s.io/autoscaling/addon-resizer
      % endif
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif