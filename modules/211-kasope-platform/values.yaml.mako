kasopePlatform:
  # -- Configuration for underlying k8ssandra-operator helm-chart. See https://github.com/k8ssandra/k8ssandra-operator/tree/main/charts/k8ssandra-operator
  k8ssandra-operator:    
    # -- In clusters where we can't or won't deploy operators, then this can be set to false.
    % if values['global']['deployOperators'] == "false":
    enabled: false
    % else:
    enabled: true
    % endif
    global:
      % if values['global']['clusterwideResources'] == "false":
      clusterScoped: false
      % else:
      clusterScoped: true
      % endif
      # -- Setting new imageConfig from k8ssandra-operator 1.27.0
      imageConfig:
        images:
          system-logger:
            repository: "k8ssandra"
            name: "system-logger"
            tag: "v1.27.1"
          config-builder:
            repository: "datastax"
            name: "cass-config-builder"
            tag: "1.0-ubi8"
          k8ssandra-client:
            repository: "k8ssandra"
            name: "k8ssandra-client"
            tag: "v0.8.3"
          reaper:
            repository: "thelastpickle"
            name: "cassandra-reaper"
            tag: "4.0.0"
          medusa:
            repository: "k8ssandra"
            name: "medusa"
            tag: "0.25.1"
        types:
          cassandra:
            repository: "k8ssandra"
            name: "cass-management-api"
            suffix: "-ubi8"
        % if 'containerRegistryBase' in values['global']:
        defaults:
          registry: ${values['global']['containerRegistryBase']}
        % endif
    % if 'containerRegistryBase' in values['global']:
    image:
      registry: ${values['global']['containerRegistryBase']}
    % endif     
    % if 'containerRegistryBase' in values['global']:
    cleaner:
      image:
        registry: ${values['global']['containerRegistryBase']}
    % endif
    serviceAccount:
      create: false
      name: "platform"
    # -- Configuration for underlying cass-operator helm-chart. See https://github.com/k8ssandra/k8ssandra/tree/main/charts/cass-operator
    cass-operator:
      % if 'containerRegistryBase' in values['global']:
      image:      
        registry: ${values['global']['containerRegistryBase']}
      % endif
      admissionWebhooks:
        enabled: false
      serviceAccount:
        create: false
        name: "platform"
    # -- CRD Upgrader is disabled by default as we manage CRDs ourselves
    disableCrdUpgraderJob: true