kyvernoPlatformNamespace: kyverno
kyvernoPlatform:
  enforceQvantelArtifactory: false
  kyverno-policies:
    enabled: false
  kyverno:
    global:
      image:
        # -- (string) Global value that allows to set a single image registry across all deployments.
        # When set, it will override any values set under `.image.registry` across the chart.
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % endif
    policyReportsCleanup:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc
    webhooksCleanup:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc
    test:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc
    cleanupJobs:
      admissionReports:
        image:
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.3_202509080945_master_90384dcc
      clusterAdmissionReports:
        image:
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.3_202509080945_master_90384dcc
      updateRequests:
        image:
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.3_202509080945_master_90384dcc
      ephemeralReports:
        image:
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.3_202509080945_master_90384dcc
      clusterEphemeralReports:
        image:
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.3_202509080945_master_90384dcc
