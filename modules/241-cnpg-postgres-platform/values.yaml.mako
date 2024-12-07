cnpgPostgresPlatform:
  monitoringPlatformEnabled: ${addon_operator['monitoringPlatformEnabled']}
  cloudnative-pg:            
    % if values['global']['deployOperators'] == "true":
    enabled: true
    % else:
    enabled: false
    % endif
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/cloudnative-pg/cloudnative-pg
      % endif
    crds:
      create: false
    % if values['global']['clusterwideResources'] == "false":
    rbac:
      create: false
    % endif
    serviceAccount:
      create: false
      name: platform
    additionalEnv:
      # renew certificates 30 days before expiration to avoid alerts in monitoring
      - name: EXPIRING_CHECK_THRESHOLD
        value: "30"
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    % if addon_operator['monitoringPlatformEnabled'] == 'true':
    monitoring:
      podMonitorEnabled: true
      podMonitorAdditionalLabels: 
        "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    % endif
  clusters:
    qvt-postgredb:
      enabled: true
      vaultConfiguration: true
      scheduledBackup: "0 0 0 * * *" # every midnight
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
        % if values['global']['configurationProfile'] not in {'dev'}:
        backup:
          retentionPolicy: "7d"
          barmanObjectStore:
            destinationPath: "s3://<your-S3-bucket-name-here>"
            s3Credentials:
              inheritFromIAMRole: true
          wal:
            compression: gzip
            maxParallel: 8
            encryption: AES256
        % endif
        
