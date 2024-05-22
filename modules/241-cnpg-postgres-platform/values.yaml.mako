cnpgPostgresPlatform:
  images:
    cloudnative-pg:
      registry: ghcr.io
      repository: cloudnative-pg/cloudnative-pg
      tag: "1.22.2"
    q-cnpg-timescale-15:
      registry: artifactory.qvantel.net
      repository: q-cnpg-timescale
      tag: "15.7-1_5_master_e1aa9a467"
    q-cnpg-timescale-16:    
      registry: artifactory.qvantel.net
      repository: q-cnpg-timescale
      tag: "16.3-1_5_master_e1aa9a467"
  cloudnative-pg:
    image:
      repository: ${values['cnpgPostgresPlatform']['images']['cloudnative-pg']['registry']}/${values['cnpgPostgresPlatform']['images']['cloudnative-pg']['repository']}      
      tag: ${values['cnpgPostgresPlatform']['images']['cloudnative-pg']['tag']}
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
  clusters:
    qvt-postgredb:
      enabled: false
      vaultConfiguration: true
      spec:
        affinity:
          topologyKey: topology.kubernetes.io/zone
        enableSuperuserAccess: true
        imageName: ${values['cnpgPostgresPlatform']['images']['q-cnpg-timescale-15']['registry']}/${values['cnpgPostgresPlatform']['images']['q-cnpg-timescale-15']['repository']}:${values['cnpgPostgresPlatform']['images']['q-cnpg-timescale-15']['tag']}
        instances: 2        
        monitoring:
          enablePodMonitor: true
        postgresql:
          parameters:
            pg_stat_statements.max: "10000"
            pg_stat_statements.track: all
            max_connections: "300"
            wal_compression: pglz
            random_page_cost: "1"
          shared_preload_libraries:
            - timescaledb
        resources:
          requests:
            memory: 1Gi
            cpu: "0.1"
        storage:
          size: 10Gi
