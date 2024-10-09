cnpgPostgresPlatform:
  monitoringPlatformEnabled: ${addon_operator['monitoringPlatformEnabled']}
  cloudnative-pg:
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/cloudnative-pg/cloudnative-pg
      % endif
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
    % if addon_operator['monitoringPlatformEnabled'] == 'true':
    monitoring:
      podMonitorEnabled: true
      podMonitorAdditionalLabels: 
        "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
      grafanaDashboard:
        create: true
        labels:
          grafana_dashboard: "1"
        annotations:
          k8s-sidecar-target-directory: /tmp/dashboards/Postgres
    % endif
  clusters:
    qvt-postgredb:
      enabled: true
      vaultConfiguration: true
      spec:
        affinity:
          % if values['global']['multiZone']['enabled']:
          topologyKey: topology.kubernetes.io/zone
          % endif
        enableSuperuserAccess: true
        % if 'containerRegistryBase' in values['global']:
        imageName: ${values['global']['containerRegistryBase']}/cloudnative-pg/q-cnpg-timescale:15.7-1_7_master_b0ee48eda
        % else:
        imageName: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:15.7-1_7_master_b0ee48eda
        % endif
        % if values['global']['configurationProfile'] in {'dev'}: 
        instances: 1
        % else:
        instances: 2
        % endif
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
