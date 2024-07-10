mariadbOperatorPlatform:
  images:
    mariadb:
      registry: docker.io
      repository: mariadb
      tag: 10.4.33
  nameOverride: "mariadb-operator-platform"
  mariadb-operator:
    image:
      repository: ${values['mariadbOperatorPlatform']['images']['mariadb-operator']['registry']}/${values['mariadbOperatorPlatform']['images']['mariadb-operator']['repository']}
      tag: ${values['mariadbOperatorPlatform']['images']['mariadb-operator']['tag']}
    webhook:
      cert:
        certManager:
          enabled: true
    metrics:
      enabled: true
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
  clusters:
    mariadb:
      enabled: true
      vaultConfiguration: true
      spec:
        image: ${values['mariadbOperatorPlatform']['images']['mariadb']['registry']}/${values['mariadbOperatorPlatform']['images']['mariadb']['repository']}:${values['mariadbOperatorPlatform']['images']['mariadb']['tag']}
        storage:
          size: 10Gi
        replicas: 2
        replication:
          enabled: true
        metrics:
          enabled: true
        affinity:
          enableAntiAffinity: true          
        % if values['global']['platformMasters']:
        nodeSelector:
          dedicated-nodes: platform-masters
        % endif
        tolerations:
          - key: "k8s.mariadb.com/ha"
            operator: "Exists"
            effect: "NoSchedule"
          - key: "dedicated-nodes"
            value: "platform-masters"
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
