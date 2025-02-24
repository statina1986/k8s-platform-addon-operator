qvantelGlue:
  monitoringPlatformEnabled: ${addon_operator['monitoringPlatformEnabled']}
  sqlinstallersCrdSync:
    enabled: true
    # -- Schedule for reconciliation. Default is "*/5 * * * *" - so every 5 minutes.
    schedule: "*/5 * * * *"
    # -- Selector for namespaces from which sync crd resources.
    namespaceSelector:
      namespaceSelector:
        nameSelector:
          matchNames: ["${values['global']['platformNamespace']}"]
  dbs:
    postgres:
      # qvt-postgredb:
      #     cluster:
      #       vaultConfiguration: true
      #       spec:
      #         affinity:
      #           topologyKey: topology.kubernetes.io/zone
      #         instances: 2
      #         enableSuperuserAccess: true
      #         imageName: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:15.7-1_7_master_b0ee48eda
      #         postgresql:
      #           parameters:
      #             pg_stat_statements.max: "10000"
      #             pg_stat_statements.track: all
      #             max_connections: "300"
      #             wal_compression: pglz
      #             random_page_cost: "1"
      #           shared_preload_libraries:
      #             - timescaledb
      #         resources:
      #           requests:
      #             memory: 1Gi
      #             cpu: "0.1"
      #         storage:
      #           size: 10Gi
      #     dbs:
      #       catalog-deployer:
      #       catalog-designer:
      #       checkpoints:
      #       customer-bpmn-executor:
      #       customer-manager:
      #       ddl:
      #         extensions:
      #           timescaledb:
      #       flex-bpmn-executor:
      #       interactions:
      #       interactions-admin:
    mariadb:
    cassandra: