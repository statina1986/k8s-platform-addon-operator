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
    mariadb:
    cassandra:
      # qvt-postgredb:
      #   cluster:
      #     spec:
      #   dbs:
      #     flex:
      #       provisios      
      #   roles:
      #     admin:
      #     readonly:
      # mariadb:
      #   dbs: