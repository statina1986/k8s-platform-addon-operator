<%
  region = values.get('awsPlatform', {}).get('region','eu-central-1')
  clusterName = values.get('awsPlatform', {}).get('clusterName','cluster-name')
  awsRegistryAccount = {}
  awsRegistryAccount['af-south-1']     = '877085696533'
  awsRegistryAccount['ap-east-1']      = '800184023465'
  awsRegistryAccount['ap-northeast-1'] = '602401143452'
  awsRegistryAccount['ap-northeast-2'] = '602401143452'
  awsRegistryAccount['ap-northeast-3'] = '602401143452'
  awsRegistryAccount['ap-south-1']     = '602401143452'
  awsRegistryAccount['ap-south-2']     = '900889452093'
  awsRegistryAccount['ap-southeast-1'] = '602401143452'
  awsRegistryAccount['ap-southeast-2'] = '602401143452'
  awsRegistryAccount['ap-southeast-3'] = '296578399912'
  awsRegistryAccount['ap-southeast-4'] = '491585149902'
  awsRegistryAccount['ca-central-1']   = '602401143452'
  awsRegistryAccount['ca-west-1']      = '761377655185'
  awsRegistryAccount['cn-north-1']     = '918309763551'
  awsRegistryAccount['cn-northwest-1'] = '961992271922'
  awsRegistryAccount['eu-central-1']   = '602401143452'
  awsRegistryAccount['eu-central-2']   = '900612956339'
  awsRegistryAccount['eu-north-1']     = '602401143452'
  awsRegistryAccount['eu-south-1']     = '590381155156'
  awsRegistryAccount['eu-south-2']     = '455263428931'
  awsRegistryAccount['eu-west-1']      = '602401143452'
  awsRegistryAccount['eu-west-2']      = '602401143452'
  awsRegistryAccount['eu-west-3']      = '602401143452'
  awsRegistryAccount['il-central-1']   = '066635153087'
  awsRegistryAccount['me-south-1']     = '558608220178'
  awsRegistryAccount['me-central-1']   = '759879836304'
  awsRegistryAccount['sa-east-1']      = '602401143452'
  awsRegistryAccount['us-east-1']      = '602401143452'
  awsRegistryAccount['us-east-2']      = '602401143452'
  awsRegistryAccount['us-gov-east-1']  = '151742754352'
  awsRegistryAccount['us-gov-west-1']  = '013241004608'
  awsRegistryAccount['us-west-1']      = '602401143452'
  awsRegistryAccount['us-west-2']      = '602401143452'
%>

awsPlatform:
  region: eu-central-1
  clusterName: cluster-name
  awsRegistry: ${awsRegistryAccount[region]}.dkr.ecr.${region}.amazonaws.com
  apiServerEndpoint: https://172.20.0.1:443 # override EKS API server endpoint
  aws-load-balancer-controller-enabled: false
  aws-load-balancer-controller:
    clusterName: ${clusterName}
    serviceAccount:
      name: platform
      create: false
    tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
  aws-efs-csi-driver-enabled: false
  aws-efs-csi-driver:
    image:
      repository: ${values['global']['containerRegistryBase']}/amazon/aws-efs-csi-driver
    sidecars:
      livenessProbe:
        image:
          repository: ${values['global']['containerRegistryBase']}/kubernetes-csi/livenessprobe
      nodeDriverRegistrar:
        image:
          repository: ${values['global']['containerRegistryBase']}/kubernetes-csi/node-driver-registrar          
      csiProvisioner:
        image:
          repository: ${values['global']['containerRegistryBase']}/kubernetes-csi/external-provisioner
    controller:
      serviceAccount:
        create: false
        name: platform
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        dedicated-nodes: platform-masters
      % endif
    node:
      serviceAccount:
        create: false
        name: platform
    storageClasses:
      # Add StorageClass resources like:
      - name: efs-sc
        #   annotations:
        #     # Use that annotation if you want this to your default storageclass
        #     storageclass.kubernetes.io/is-default-class: "true"
        mountOptions:
          - tls
        parameters:
          provisioningMode: efs-ap
          fileSystemId: SYSTEM_EFS_VALUE_HERE
          directoryPerms: "700"
          # gidRangeStart: "1000"
          # gidRangeEnd: "2000"
          uid: "0"
          gid: "0"
          basePath: "/dynamic_provisioning"
        reclaimPolicy: Delete
        volumeBindingMode: Immediate
  aws-ebs-csi-driver-enabled: false
  aws-ebs-csi-driver:
    image:
        repository: ${values['global']['containerRegistryBase']}/ebs-csi-driver/aws-ebs-csi-driver
    sidecars:
      provisioner:
        image:
          repository: ${values['global']['containerRegistryBase']}/kubernetes-csi/external-provisioner
      attacher:
        image:
          repository: ${values['global']['containerRegistryBase']}/kubernetes-csi/external-attacher
      snapshotter:
        image:
          repository: ${values['global']['containerRegistryBase']}/external-snapshotter/csi-snapshotter
      livenessProbe:
        image:
          repository: ${values['global']['containerRegistryBase']}/kubernetes-csi/livenessprobe
      resizer:
        image:
          repository: ${values['global']['containerRegistryBase']}/kubernetes-csi/external-resizer
      nodeDriverRegistrar:
        image:
          repository: ${values['global']['containerRegistryBase']}/kubernetes-csi/node-driver-registrar
      volumemodifier:
        image:
          repository: ${values['global']['containerRegistryBase']}/ebs-csi-driver/volume-modifier-for-k8s
    controller:
      serviceAccount:
        create: false
        name: platform
    node:
      serviceAccount:
        create: false
        name: platform
    storageClasses:
      - name: gp3
        # annotation metadata
        annotations:
          storageclass.kubernetes.io/is-default-class: "true"
        # defaults to WaitForFirstConsumer
        volumeBindingMode: WaitForFirstConsumer
        # defaults to Delete
        reclaimPolicy: Delete
        allowVolumeExpansion: true
        parameters:
          type: gp3
  aws-vpc-cni-enabled: false
  aws-vpc-cni:
    eniConfig:
      region: ${region}
    image:
      region: ${region}
      account: '${awsRegistryAccount[region]}'
    nodeAgent:
      image:
        region: ${region}
        account: '${awsRegistryAccount[region]}'
    env:
      ENABLE_PREFIX_DELEGATION: "true"
    init:
      image:
        region: ${region}
        account: '${awsRegistryAccount[region]}'
  awsKubeProxyEnabled: false
  awsKubeProxy:      
    % if values['global']['kubernetesVersion'] in {'1.25'}: 
    image: "v1.25.16-minimal-eksbuild.1"
    % elif values['global']['kubernetesVersion'] in {'1.26'}:
    image: "v1.26.11-minimal-eksbuild.4"
    % elif values['global']['kubernetesVersion'] in {'1.27'}:
    image: "v1.27.8-minimal-eksbuild.4"
    % elif values['global']['kubernetesVersion'] in {'1.28'}:
    image: "v1.28.4-minimal-eksbuild.4"
    % elif values['global']['kubernetesVersion'] in {'1.29'}:
    image: "v1.29.0-minimal-eksbuild.1"
    % else:
    image: "v1.25.16-minimal-eksbuild.1"
    % endif
    
