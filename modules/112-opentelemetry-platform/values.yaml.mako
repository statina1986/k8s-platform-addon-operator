opentelemetryPlatform:
  opentelemetry-operator:
    enabled: true
    manager:
      % if 'containerRegistryBase' in values['global']:
      image:
        repository: ${values['global']['containerRegistryBase']}/otel-operator/open-telemetry/opentelemetry-operator/opentelemetry-operator
        tag: v0.93.0
      % endif
      collectorImage:
        % if 'containerRegistryBase' in values['global']:
        repository: ${values['global']['containerRegistryBase']}/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s
        tag: 0.131.1
        % endif
      autoInstrumentationImage:
        java:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/otel-operator/autoinstrumentation-java
          tag: 2.18.1
          % endif
        python:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/otel-operator/autoinstrumentation-python
          tag: 0.57b0
          % endif
        nodejs:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/otel-operator/autoinstrumentation-nodejs
          tag: 0.62.0
          % endif
        dotnet:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/otel-operator/autoinstrumentation-dotnet
          tag: 1.12.0
          % endif
        apacheHttpd:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/otel-operator/autoinstrumentation-apache-httpd
          tag: 1.0.4
          % endif
      serviceMonitor:
        enabled: ${addon_operator['monitoringPlatformEnabled']}
        extraLabels:
          "release": "${values['global']['helmReleaseNamePrefix']}monitoring-platform"
    kubeRBACProxy:
      enabled: true
      % if 'containerRegistryBase' in values['global']:
      image:
        repository: ${values['global']['containerRegistryBase']}/brancz/kube-rbac-proxy
        tag: v0.19.1
      % endif