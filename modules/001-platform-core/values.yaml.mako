platformCore:
  corednsEnabled: false
  localStorageEnabled: false
  eksUdevEnabled: false
  cleanUpControllerEnabled: false
  turndown:
    enabled: "false"
  coredns:
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/coredns/coredns
      % endif
    autoscaler:
      image:
        % if 'containerRegistryBase' in values['global']:
        repository: ${values['global']['containerRegistryBase']}/cpa/cluster-proportional-autoscaler
        % endif
  local-static-provisioner:
    classes:
      - name: nvme-ssd
        hostDir: /dev/disk/kubernetes
        storageClass: true
    nodeSelector:
      dedicated-nodes: local-storage
    tolerations:
      - key: "dedicated-nodes"
        operator: "Equal"
        value: "local-storage"
        effect: "NoSchedule"
    % if 'containerRegistryBase' in values['global']:
    image: ${values['global']['containerRegistryBase']}/sig-storage/local-volume-provisioner:v2.6.0
    % endif