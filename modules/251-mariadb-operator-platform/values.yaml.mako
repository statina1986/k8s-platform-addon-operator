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
        value: ${values['global']['containerRegistryBase']}/mariadb-operator/mariadb-operator:25.08.3
      - name: MARIADB_GALERA_INIT_IMAGE
        value: ${values['global']['containerRegistryBase']}/mariadb-operator/mariadb-operator:25.08.3
      - name: MARIADB_OPERATOR_IMAGE
        value: ${values['global']['containerRegistryBase']}/mariadb-operator/mariadb-operator:25.08.3
      - name: RELATED_IMAGE_EXPORTER
        value: ${values['global']['containerRegistryBase']}/prom/mysqld-exporter:v0.15.1
      - name: RELATED_IMAGE_EXPORTER_MAXSCALE
        value: ${values['global']['containerRegistryBase']}/mariadb/maxscale-prometheus-exporter-ubi:v0.0.1
      - name: RELATED_IMAGE_MAXSCALE
        value: ${values['global']['containerRegistryBase']}/mariadb/maxscale:23.08.5
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