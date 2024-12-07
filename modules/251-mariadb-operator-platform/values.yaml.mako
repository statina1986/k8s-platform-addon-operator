mariadbOperatorPlatform:
  images:
    mariadb:
      registry: docker.io
      repository: mariadb
      tag: 10.6.19
  nameOverride: "mariadb-operator-platform"
  mariadb-operator:
    % if values['global']['clusterwideResources'] == "false":
    currentNamespaceOnly: true
    % endif
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/mariadb-operator/mariadb-operator
      % endif
    webhook:
      % if values['global']['clusterwideResources'] == "false":
      enabled: false
      % endif
      % if 'containerRegistryBase' in values['global']:
      image:
        repository: ${values['global']['containerRegistryBase']}/mariadb-operator/mariadb-operator
      % endif
      % if addon_operator['monitoringPlatformEnabled'] == 'true':
      serviceMonitor:
        enabled: true
        additionalLabels:
          "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
       % endif
      cert:
        certManager:
          enabled: true
    % if addon_operator['monitoringPlatformEnabled'] == 'true':
    metrics:
      enabled: true
      serviceMonitor:
        enabled: true
        additionalLabels:
          "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    % endif  
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    % if 'containerRegistryBase' in values['global']:
    extraEnv:
      - name: MARIADB_GALERA_AGENT_IMAGE
        value: ${values['global']['containerRegistryBase']}/mariadb-operator/mariadb-operator:0.35.1
      - name: MARIADB_GALERA_INIT_IMAGE
        value: ${values['global']['containerRegistryBase']}/mariadb-operator/mariadb-operator:0.35.1
      - name: MARIADB_OPERATOR_IMAGE
        value: ${values['global']['containerRegistryBase']}/mariadb-operator/mariadb-operator:0.35.1
      - name: RELATED_IMAGE_EXPORTER
        value: ${values['global']['containerRegistryBase']}/prom/mysqld-exporter:v0.15.1
      - name: RELATED_IMAGE_EXPORTER_MAXSCALE
        value: ${values['global']['containerRegistryBase']}/mariadb/maxscale-prometheus-exporter-ubi:v0.0.1
      - name: RELATED_IMAGE_MAXSCALE
        value: ${values['global']['containerRegistryBase']}/mariadb/maxscale:23.08.5
    % endif
  clusters:
    mariadb:
      enabled: true
      vaultConfiguration: true
      spec:
        % if 'containerRegistryBase' in values['global']:
        image: ${values['global']['containerRegistryBase']}/library/mariadb:10.6.19
        % endif
        storage:
          size: 10Gi
        % if values['global']['configurationProfile'] in {'dev'}: 
        replication:
          enabled: false
        replicas: 1
        % else:
        replicas: 3
        replication:
          enabled: true
        % endif
        % if addon_operator['monitoringPlatformEnabled'] == 'true':
        metrics:
          enabled: true
          serviceMonitor:
            prometheusRelease: "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
        % endif  
        affinity:
          antiAffinityEnabled: true      
        % if values['global']['platformMasters']:
        nodeSelector:
          ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
        % endif
        tolerations:
          - key: "k8s.mariadb.com/ha"
            operator: "Exists"
            effect: "NoSchedule"
          - key: "${values['global']['platformMastersKey']}"
            value: "${values['global']['platformMastersValue']}"
            operator: "Equal"
            effect: "NoSchedule"
        podDisruptionBudget:
          maxUnavailable: 33%
        updateStrategy:
          type: RollingUpdate
        myCnf: |
          [mariadb]
          bind-address=*
          default_storage_engine=InnoDB
          binlog_format=row
          innodb_autoinc_lock_mode=2
          max_allowed_packet=256M
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            memory: 1Gi