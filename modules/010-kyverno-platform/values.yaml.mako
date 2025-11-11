kyvernoPlatformNamespace: kyverno
kyvernoPlatform:
  # -- Configuration for underlying Kyverno Policies helm-chart. See https://github.com/kyverno/kyverno/blob/main/charts/kyverno-policies/README.md
  # @default -- see child items doc
  kyverno-policies:
    # -- Toggle to enable Kyverno Policies chart deployment
    enabled: false
    # -- Pod Security Standard profile (`baseline`, `restricted`, `privileged`, `custom`).
    # For more info https://kyverno.io/policies/pod-security.
    podSecurityStandard: baseline
    # -- Pod Security Standard (`low`, `medium`, `high`).
    podSecuritySeverity: medium
  # -- Configuration for underlying Kyverno helm-chart. See https://github.com/kyverno/kyverno/blob/main/charts/kyverno/README.md
  kyverno:
    global:
      image:
        # -- (string) Global value that allows to set a single image registry across all deployments.
        # When set, it will override any values set under `.image.registry` across the chart.
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
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
    crds:
      # -- We deploy all CRDs under /resources folder.
      install: false
      migration:
        # -- Enable CRDs migration using helm post upgrade hook
        enabled: false
    policyExceptions:
      # -- Enables the feature
      enabled: false
      # -- Restrict policy exceptions to a single namespace
      # Set to "*" to allow exceptions in all namespaces
      namespace: ''
    test:
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
    
    