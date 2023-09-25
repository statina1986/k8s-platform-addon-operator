metricsPlatform:
  metrics-server:
    tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif