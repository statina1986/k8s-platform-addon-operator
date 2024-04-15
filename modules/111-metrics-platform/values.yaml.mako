metricsPlatform:
  metrics-server:
    tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif