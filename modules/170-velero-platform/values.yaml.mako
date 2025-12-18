veleroPlatform:
  # -- Configuration for underlying velero helm-chart. See https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero#configuration
  velero:  
    % if 'containerRegistryBase' in values['global']:
    image:
      repository: ${values['global']['containerRegistryBase']}/velero/velero
      tag: v1.17.0
    % endif
    deployNodeAgent: true
    configuration:
      features: EnableCSI
      defaultSnapshotMoveData: true
    credentials:
      useSecret: false
    serviceAccount:
      server:
        create: false
        name: platform
    % if addon_operator['awsPlatformEnabled'] == 'true':
    initContainers:
      - name: velero-plugin-for-aws
        image: ${values['global'].get('containerRegistryBase','docker.io')}/velero/velero-plugin-for-aws:v1.13.0
        volumeMounts:
          - mountPath: /target
            name: plugins
    % endif