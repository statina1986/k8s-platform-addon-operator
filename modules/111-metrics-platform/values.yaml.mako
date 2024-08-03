metricsPlatform:
  metrics-server:
    image:
      repository: ${values['global']['containerRegistryBase']}/metrics-server/metrics-server
    addonResizer:
      image:
        repository: ${values['global']['containerRegistryBase']}/autoscaling/addon-resizer 
    tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif