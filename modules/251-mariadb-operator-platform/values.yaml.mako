mariadbOperatorPlatform:
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

    config:
      % if 'containerRegistryBase' in values['global']:
      # -- Default MariaDB image
      mariadbImage: ${values['global']['containerRegistryBase']}/library/mariadb:11.4.3
      # -- Default MaxScale image
      maxscaleImage: ${values['global']['containerRegistryBase']}/mariadb/maxscale:23.08.5
      # -- Default MariaDB exporter image
      exporterImage: ${values['global']['containerRegistryBase']}/prom/mysqld-exporter:v0.15.1
      # -- Default MaxScale exporter image
      exporterMaxscaleImage: ${values['global']['containerRegistryBase']}/mariadb/maxscale-prometheus-exporter-ubi:v0.0.1
      # -- Default SQL exporter image
      sqlExporterImage: ${values['global']['containerRegistryBase']}/burningalchemist/sql_exporter:0.18
      % else:
      # -- Default MariaDB image
      mariadbImage: docker-registry1.mariadb.com/library/mariadb:11.4.3
      # -- Default MaxScale image
      maxscaleImage: docker-registry2.mariadb.com/mariadb/maxscale:23.08.5
      # -- Default MariaDB exporter image
      exporterImage: prom/mysqld-exporter:v0.15.1
      # -- Default MaxScale exporter image
      exporterMaxscaleImage: docker-registry2.mariadb.com/mariadb/maxscale-prometheus-exporter-ubi:v0.0.1
      # -- Default SQL exporter image
      sqlExporterImage: docker.io/burningalchemist/sql_exporter:0.18
      % endif