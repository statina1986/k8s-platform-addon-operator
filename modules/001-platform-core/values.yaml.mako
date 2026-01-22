platformCore:
  appTenantRbacEnabled: false
  appTenantNamespaces: []
  localStorageEnabled: false
  cleanUpControllerEnabled: false
  snapshotControllerEnabled: false
  local-static-provisioner:
    classes:
      - name: nvme-ssd
        hostDir: /dev/disk/kubernetes
        storageClass: true
    % if values['global']['localStorage']:
    nodeSelector:
      ${values['global']['localStorageKey']}: ${values['global']['localStorageValue']}
    % endif
    tolerations:
      - key: ${values['global']['localStorageKey']}
        operator: "Equal"
        value: ${values['global']['localStorageValue']}
        effect: "NoSchedule"
    % if 'containerRegistryBase' in values['global']:
    image: ${values['global']['containerRegistryBase']}/sig-storage/local-volume-provisioner:v2.6.0
    % endif
  cleanUpStorageClass: nvme-ssd