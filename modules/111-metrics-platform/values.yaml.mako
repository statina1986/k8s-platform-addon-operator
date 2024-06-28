metricsPlatform:
  metrics-server:
    image:
      repository: ${values['metricsPlatform']['images']['metrics-server']['registry']}/${values['metricsPlatform']['images']['metrics-server']['repository']}
      tag: ${values['metricsPlatform']['images']['metrics-server']['tag']}
    addonResizer:
      image:
        repository: ${values['metricsPlatform']['images']['addonResizer']['registry']}/${values['metricsPlatform']['images']['addonResizer']['repository']}
        tag: ${values['metricsPlatform']['images']['addonResizer']['tag']}
    tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif