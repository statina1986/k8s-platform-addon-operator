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
      % else:
      # -- Default MariaDB image
      mariadbImage: docker-registry1.mariadb.com/library/mariadb:11.4.3
      # -- Default MaxScale image
      maxscaleImage: docker-registry2.mariadb.com/mariadb/maxscale:23.08.5
      # -- Default MariaDB exporter image
      exporterImage: prom/mysqld-exporter:v0.15.1
      # -- Default MaxScale exporter image
      exporterMaxscaleImage: docker-registry2.mariadb.com/mariadb/maxscale-prometheus-exporter-ubi:v0.0.1
      % endif
      
  
  # -- Common configurations for MariaDB databases
  # @default -- see child items docs
  common:
    # -- Default values for MariaDB clusters. See `example-mariadb` for reference.
    # With this field you can configure common values for all MariaDB clusters, e.g. backup location and schedule.
    defaultCluster: {}
    # -- (tpl/string) Default spec for MariaDB clusters. See `example-mariadb` for reference.
    # This is templated field which is rendered for each cluster from `mariadbOperatorPlatform.clusters`. 
    # With this field you can override default cluster template for complex cases and utilize helm templating in it.
    # Scope for the template contains fields: 
    # \newline
    # * addonOperator: content from Addon Operator configmap. You can check if some modules, e.f. monitoring-platform are enabled.
    # \newline
    # * root: root context of 'mariadbOperatorPlatform' module, containing all Values for the module.
    # \newline
    # * cluster: content of 'cluster' field for rendered cluster.
    # @notationType -- tpl
    defaultClusterTemplate: |
      {{- if eq $.addonOperator.vaultPlatformEnabled "true" }}
      vaultConfiguration: true
      {{- end }}
      spec:
        {{- if $.root.Values.global.platformMasters }}
        nodeSelector:
          {{ $.root.Values.global.platformMastersKey }}: {{ $.root.Values.global.platformMastersValue }}
        {{- end }}
        storage:
          size: 10Gi
        {{- if eq $.root.Values.global.configurationProfile "dev" }}
        replicas: 1
        {{- else }}
        replicas: 3
        galera:
          enabled: true
          config:
            reuseStorageVolume: true
          providerOptions:
            gcache.size: 128M
        maxScale:
          enabled: true
          replicas: 2
        {{- end }}
        {{- if $.addonOperator.monitoringPlatformEnabled }}
        metrics:
          enabled: true
          serviceMonitor:
            prometheusRelease: "{{ $.root.Values.global.helmReleaseNamePrefix }}monitoring-platform"
        {{- end }}
        serviceAccountName: "platform"
        affinity:
          antiAffinityEnabled: true  
        tolerations:
          - key: "k8s.mariadb.com/ha"
            operator: "Exists"
            effect: "NoSchedule"
          - key: "{{ $.root.Values.global.platformMastersKey }}"
            value: "{{ $.root.Values.global.platformMastersValue }}"
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
  clusters:
    mariadb:
      enabled: true
      vaultConfiguration: true