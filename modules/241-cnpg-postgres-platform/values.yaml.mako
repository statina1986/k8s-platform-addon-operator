cnpgPostgresPlatform:
  monitoringPlatformEnabled: ${addon_operator['monitoringPlatformEnabled']}
  cloudnative-pg:            
    % if values['global']['deployOperators'] == "true":
    enabled: true
    % else:
    enabled: false
    % endif
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/cloudnative-pg/cloudnative-pg
      % endif
    crds:
      create: false
    % if values['global']['clusterwideResources'] == "false":
    rbac:
      create: false
    config:
      data:
        WATCH_NAMESPACE: ${values['global']['platformNamespace']}
    % endif
    serviceAccount:
      create: false
      name: platform
    additionalEnv:
      # renew certificates 30 days before expiration to avoid alerts in monitoring
      - name: EXPIRING_CHECK_THRESHOLD
        value: "30"
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
  clusters:
    qvt-postgredb:
      enabled: true
      vaultConfiguration: true
      scheduledBackup: "0 0 0 * * *" # every midnight
        
