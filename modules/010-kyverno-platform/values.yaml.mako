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
        tag: 1.2.0_10_5193dbce5
    webhooksCleanup:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.2.0_10_5193dbce5
    test:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.2.0_10_5193dbce5
