% if addon_operator['monitoringPlatformEnabled'] == 'true':
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    release: monitoring-platform
  name: consul-service-monitor
spec:
  endpoints:
    - honorTimestamps: true
      path: '/v1/agent/metrics'
      scheme: http
      scrapeTimeout: 30s
      params:
        format: ['prometheus']
      targetPort: 8500
  selector:
    matchLabels:
      app: consul
      release: consul-platform
      component: server
% endif 