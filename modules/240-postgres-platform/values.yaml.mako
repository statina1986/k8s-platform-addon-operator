postgresPlatform:
  postgres-operator:
    configKubernetes:
      enable_pod_antiaffinity: true
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif    
  postgres-operator-ui:
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"    
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
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
      spec:
        teamId: "qvt"
        dockerImage: artifactory.qvantel.net/qvantel-spilo:2.1-p7.20221130075959_postgres-14_b47cdbd7        
        volume:
          size: 100Gi
        numberOfInstances: 2
        tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule" 
        % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes    
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                - key: dedicated-nodes
                  operator: In
                  values:
                  - platform-masters
        % endif
        resources:
          limits:
            cpu: "100"
            memory: 6Gi
          requests:
            cpu: "1"
            memory: 2Gi
        postgresql:
          version: "13"