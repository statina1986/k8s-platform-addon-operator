% if addon_operator['monitoringPlatformEnabled'] == 'true':
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: monitoring-platform-kube-p-redis.rules
  namespace: {{.Release.Namespace}}
  generation: 1
  annotations:
    meta.helm.sh/release-name: monitoring-platform
    meta.helm.sh/release-namespace: {{.Release.Namespace}}
  labels:
    app: kube-prometheus-stack
    release: monitoring-platform
spec:
  groups:
  - name: redis.alerts
    rules:
    - alert: RedisDown
      expr: redis_up != 1
      for: 2m
      labels:
        severity: critical
      annotations:
        message: Redis {{` {{ $labels.pod_name }} `}} is down.
        procedure: "Contact NoSQL team urgently if the instance keeps down"
    - alert: RedisHasBlockedClients
      expr: redis_blocked_clients != 0
      for: 1m
      labels:
        severity: critical
      annotations:
        message: Blocked Redis clients detected on {{` {{ $labels.instance }} `}}
        procedure: "Contact NoSQL team during business hours"
    - alert: AmountOfRedisClients
      expr: redis_connected_clients/redis_config_maxclients * 100 > 60 AND redis_connected_clients/redis_config_maxclients * 100 < 80
      for: 1m
      labels:
        severity: warning
      annotations:
        message: Redis has reached 60% of maximum clients configured on {{` {{ $labels.instance }} `}}
        procedure: "Inform NoSQL team"
    - alert: HighAmountOfRedisClients
      expr: redis_connected_clients/redis_config_maxclients * 100 > 80
      for: 1m
      labels:
        severity: critical
      annotations:
        message: Redis has reached 80% of maximum clients configured on {{` {{ $labels.instance }} `}}
        procedure: "Contact NoSQL urgently to verify the potential risk"
    - alert: RedisTimeCall
      expr: delta(redis_commands_duration_seconds_total{cmd!~".*flush.*"}[2h]) / delta(redis_commands_duration_seconds_total{cmd!~".*flush.*"}[2h]) > 3
      for: 1m
      labels:
        severity: warning
      annotations:
        message: Execution of command {{` {{ $labels.cmd }}  `}} has taken on average {{` {{ $value | humanizeDuration }} `}} on {{` {{ $labels.instance }} `}} in last 2 hours.
        procedure: "Inform NoSQL team"
    - alert: RedisMasterDown
      expr: redis_instance_info{role="master"} != 1 OR absent(redis_instance_info{role="master"})
      for: 2m
      labels:
        severity: critical
      annotations:
        message: Current Redis master is down
        procedure: "Contact NoSQL team urgently"
% endif 