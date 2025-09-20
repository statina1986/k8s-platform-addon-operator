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
        {{- if eq $.addonOperator.monitoringPlatformEnabled "true" }}
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
        {{- if eq $.addonOperator.monitoringPlatformEnabled "true" }}
          performance_schema=on
          init_file=/etc/mysql/init-sql/init.sql

          # statements consumers
          performance-schema-consumer-events-statements-current=ON
          performance-schema-consumer-events-statements-history=ON
          performance-schema-consumer-events-statements-history-long=ON
          performance-schema-consumer-statements-digest=ON

          # waits consumers
          performance-schema-consumer-events-waits-current=ON
          performance-schema-consumer-events-waits-history=ON
          performance-schema-consumer-events-waits-history-long=ON

          # stages consumers
          performance-schema-consumer-events-stages-current=ON
          performance-schema-consumer-events-stages-history=ON
          performance-schema-consumer-events-stages-history-long=ON
        volumes:
          - name: init-sql
            configMap:
              name: {{ $.clusterName }}-init-sql
        volumeMounts:
          - name: init-sql
            mountPath: /etc/mysql/init-sql
            readOnly: true
        {{- end }} 
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            memory: 1Gi 
      defaultSqlExporter:
        service:
          port: 9399
        # Main config for sql_exporter. DSN is injected at runtime by init container.
        config:
          content: |
            global:
              scrape_timeout_offset: 500ms
            target:
              # DSN injected by init container via placeholder substitution
              data_source_name: "__DSN__"
              collectors:
                - mariadb_custom
            collectors:
              - collector_name: mariadb_custom
                metrics:
                  - metric_name: mariadb_threads_connected
                    type: gauge
                    help: Number of currently open connections
                    values: [threads_connected]
                    query: |
                      SELECT VARIABLE_VALUE AS threads_connected FROM information_schema.GLOBAL_STATUS  WHERE VARIABLE_NAME = 'Threads_connected'
                  - metric_name: mariadb_uptime_seconds
                    type: gauge
                    help: Server uptime in seconds
                    values: [uptime]
                    query: |
                      SELECT VARIABLE_VALUE AS uptime FROM INFORMATION_SCHEMA.GLOBAL_STATUS WHERE VARIABLE_NAME = 'UPTIME'
                  - metric_name: mariadb_wait_event_latency_seconds
                    type: gauge
                    help: Aggregated wait event latency per query from performance schema
                    key_labels: [query_id, query, database_name, wait_event_name, event_type, event_subtype]
                    value_label: metric
                    values: [wait_count, total_wait_sec, avg_wait_sec, max_wait_sec, exec_count, stmt_total_latency_sec]
                    query: |
                      SELECT
                        COALESCE(es.DIGEST, SHA1(COALESCE(es.SQL_TEXT, '')))           AS query_id,
                        COALESCE(es.DIGEST_TEXT, es.SQL_TEXT, '[unknown]')             AS query,
                        COALESCE(es.CURRENT_SCHEMA, 'unknown')                         AS database_name,
                        w.EVENT_NAME                                                   AS wait_event_name,
                        SUBSTRING_INDEX(w.EVENT_NAME, '/', 1)                          AS event_type,
                        SUBSTRING_INDEX(SUBSTRING_INDEX(w.EVENT_NAME,'/',3), '/', -2)  AS event_subtype,
                        COUNT(*)                                                       AS wait_count,
                        ROUND(SUM(w.TIMER_WAIT) / 1e12, 6)                             AS total_wait_sec,
                        ROUND(AVG(w.TIMER_WAIT) / 1e12, 6)                             AS avg_wait_sec,
                        ROUND(MAX(w.TIMER_WAIT) / 1e12, 6)                             AS max_wait_sec,
                        COUNT(DISTINCT es.EVENT_ID)                                    AS exec_count,
                        ROUND(SUM(es.TIMER_WAIT) / 1e12, 6)                            AS stmt_total_latency_sec
                      FROM performance_schema.events_waits_history_long AS w
                      LEFT JOIN performance_schema.events_stages_history_long AS s
                        ON  w.NESTING_EVENT_TYPE = 'STAGE'
                        AND s.THREAD_ID          = w.THREAD_ID
                        AND s.EVENT_ID           = w.NESTING_EVENT_ID
                        AND s.NESTING_EVENT_TYPE = 'STATEMENT'
                      JOIN performance_schema.events_statements_history_long AS es
                        ON es.THREAD_ID = w.THREAD_ID
                       AND es.EVENT_ID  = CASE
                                            WHEN w.NESTING_EVENT_TYPE = 'STATEMENT'
                                              THEN w.NESTING_EVENT_ID
                                            ELSE s.NESTING_EVENT_ID
                                          END
                      GROUP BY
                        query_id, query, database_name,
                        wait_event_name, event_type, event_subtype
                      ORDER BY total_wait_sec DESC
                      LIMIT 100;
  clusters:
    mariadb:
      enabled: true
      vaultConfiguration: true
