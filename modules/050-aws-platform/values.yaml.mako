<%
  region = values.get('awsPlatform', {}).get('region','eu-central-1')
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
  eksUdevEnabled: false

  # @schema
  # required: true
  # @schema
  # -- **Required.** AWS Region where cluster is deployed. 
  region: eu-central-1
  # -- EKS cluster name. Defaults to the name from `global.clusterName`
  clusterName: ${values['global']['clusterName']}
  # -- ECR registry for AWS images. By default is automatically assigned based on configured `region`
  awsRegistry: ${awsRegistryAccount[region]}.dkr.ecr.${region}.amazonaws.com
  # @schema
  # required: true
  # @schema
  # -- **Required.** EKS API server endpoint.
  apiServerEndpoint: null
  # @schema
  # required: true
  # @schema
  # -- **Required.** Default tags to be added for AWS Resources provisioned by this module (loadbalancers, ebs volumes, etc). If you do not want to add tags, provide `{}`.
  tags: null
  
  # -- Deploy aws-load-balancer-controller helm-chart. 
  aws-load-balancer-controller-enabled: false
  # -- Configuration for underlying aws-load-balancer-controller helm-chart. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/README.md#configuration for details.
  aws-load-balancer-controller:
    defaultTags:
      ${values['awsPlatform']['tags']}
    clusterName: ${values['global']['clusterName']}
    serviceAccount:
      name: platform
      create: false
    tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    
  # -- Deploy aws-efs-csi-driver helm-chart. 
  aws-efs-csi-driver-enabled: false
  # -- Configuration for underlying aws-efs-csi-driver helm-chart. See https://github.com/kubernetes-sigs/aws-efs-csi-driver for details.
  aws-efs-csi-driver:
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/amazon/aws-efs-csi-driver
      % endif
    sidecars:
      livenessProbe:
        image: 
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/csi-components/livenessprobe
          % endif
      nodeDriverRegistrar:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/csi-components/csi-node-driver-registrar
          % endif
      csiProvisioner:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/csi-components/csi-provisioner
          % endif
    controller:
      serviceAccount:
        create: false
        name: platform
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
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

  # -- Deploy aws-ebs-csi-driver helm-chart.
  aws-ebs-csi-driver-enabled: false
  # -- Configuration for underlying aws-ebs-csi-driver helm-chart. See https://github.com/kubernetes-sigs/aws-ebs-csi-driver for details.
  aws-ebs-csi-driver:
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/ebs-csi-driver/aws-ebs-csi-driver
      % endif
    sidecars:
      provisioner:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/csi-components/csi-provisioner
          % endif
      attacher:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/csi-components/csi-attacher
          % endif
      snapshotter:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/csi-components/csi-snapshotter
          % endif
      livenessProbe:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/csi-components/livenessprobe
          % endif
      resizer:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/csi-components/csi-resizer
          % endif
      nodeDriverRegistrar:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/csi-components/csi-node-driver-registrar
          % endif
      volumemodifier:
        image:
          % if 'containerRegistryBase' in values['global']:
          repository: ${values['global']['containerRegistryBase']}/ebs-csi-driver/volume-modifier-for-k8s
          % endif
    controller:
      extraVolumeTags:
        ${values['awsPlatform']['tags']}
      serviceAccount:
        create: false
        name: platform
    node:
      enableWindows: false
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
          tagSpecification_name: "Name=${values['global']['clusterName']}-{{ .PVCName }}"
      - name: st1        
        # defaults to WaitForFirstConsumer
        volumeBindingMode: WaitForFirstConsumer
        # defaults to Delete
        reclaimPolicy: Delete
        allowVolumeExpansion: true
        parameters:
          type: st1
          tagSpecification_name: "Name=${values['global']['clusterName']}-{{ .PVCName }}"
  # -- Deploy aws-vpc-cni helm-chart.
  aws-vpc-cni-enabled: false
  # -- Configuration for underlying aws-vpc-cni helm-chart. See https://github.com/aws/amazon-vpc-cni-k8s/tree/master/charts/aws-vpc-cni#configuration for details.
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
  # -- Deploy EKS kube-proxy.
  awsKubeProxyEnabled: false
  # -- Configuration for EKS kube-proxy. 
  awsKubeProxy:
    # -- Mako templating to match kube-proxy image to recommended as of 1st of Oct 2025
    # https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html#managing-kube-proxy-images
    % if values['global']['kubernetesVersion'] in {'1.28'}:
    image: "v1.28.15-minimal-eksbuild.31"
    % elif values['global']['kubernetesVersion'] in {'1.29'}:
    image: "v1.29.15-minimal-eksbuild.16"
    % elif values['global']['kubernetesVersion'] in {'1.30'}:
    image: "v1.30.14-minimal-eksbuild.8"
    % elif values['global']['kubernetesVersion'] in {'1.31'}:
    image: "v1.31.10-minimal-eksbuild.8"
    % elif values['global']['kubernetesVersion'] in {'1.32'}:
    image: "v1.32.6-minimal-eksbuild.8"
    % elif values['global']['kubernetesVersion'] in {'1.33'}:
    image: "v1.33.3-minimal-eksbuild.6"
    % else:
    image: "v1.28.15-minimal-eksbuild.31"
    % endif
    
