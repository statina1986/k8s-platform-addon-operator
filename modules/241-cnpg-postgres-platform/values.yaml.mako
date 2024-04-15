cnpgPostgresPlatform:
  cloudnative-pg:    
    crds:
      create: false
    serviceAccount:
      create: false
      name: platform
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"      
    % if values['global']['platformMasters']:
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    monitoring:
      podMonitorEnabled: true
      grafanaDashboard:
        create: true
        labels:
          grafana_dashboard: "1"
        annotations:
          k8s-sidecar-target-directory: /tmp/dashboards/Postgres
  cluster-qvt-postgredb:
    enabled: false
    fullnameOverride: qvt-postgredb
    vaultConfiguration: true 

    mode: standalone
    cluster:
      instances: 2
      imageName: artifactory.qvantel.net/imusmanmalik/timescaledb-postgis:15-3.4
      monitoring:
        enabled: true
      affinity:      
        topologyKey: topology.kubernetes.io/zone 
        tolerations:
          - key: "dedicated-nodes"
            value: "platform-masters"
            operator: "Equal"
            effect: "NoSchedule"
        % if values['global']['platformMasters']:
        nodeSelector:
          dedicated-nodes: platform-masters
        % endif
    backups:
      enabled: false
