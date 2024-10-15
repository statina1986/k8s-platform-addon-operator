postgresPlatform:
  postgres-operator:
    configKubernetes:
      enable_pod_antiaffinity: true
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif   
  postgres-operator-ui:
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    envs:
      operatorApiUrl: "http://postgres-platform-postgres-operator:8080"
      operatorClusterNameLabel: "cluster-name"
      resourcesVisible: "False"
      targetNamespace: "platform"
      teams:
        - "qvt"
  clusters:
    qvt-postgredb:
      enabled: true
      vaultConfiguration: true
      spec:
        teamId: "qvt"
        dockerImage: artifactory.qvantel.net/qvantel-spilo:2.1-p7.20221130075959_postgres-14_b47cdbd7        
        volume:
          size: 100Gi
        numberOfInstances: 2
        tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule" 
        % if values['global']['platformMasters']:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                - key: ${values['global']['platformMastersKey']}
                  operator: In
                  values:
                  - ${values['global']['platformMastersValue']}
        % endif
        % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run postgres with higher CPU values
        resources:
          limits:
            cpu: "100"
            memory: 6Gi
          requests:
            cpu: "1"
            memory: 2Gi
        postgresql:
          version: "13"
        % else:
        resources:
          limits:
            cpu: "1000m"
            memory: 6Gi
          requests:
            cpu: "250m"
            memory: 2Gi
        postgresql:
          version: "13"
        % endif
