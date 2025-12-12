# -- Default configurations for metric platform
metricsPlatform:
  metrics-server:
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/metrics-server/metrics-server
      % endif
    addonResizer:
      image:
        % if 'containerRegistryBase' in values['global']:
        repository: ${values['global']['containerRegistryBase']}/autoscaling/addon-resizer
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