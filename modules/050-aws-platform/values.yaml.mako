awsPlatform:
  region: eu-central-1  
  apiServerEndpoint: https://172.20.0.1:443 # provide EKS API server endpoint
  aws-load-balancer-controller-enabled: true
  aws-load-balancer-controller:
    clusterName: cluster-name
    serviceAccount:
      name: platform
      create: false
    tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
  aws-efs-csi-driver-enabled: false
  aws-efs-csi-driver:
    controller:
      serviceAccount:
        create: false
        name: platform
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
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
      % endif
  % if values['awsPlatform']['region'] == 'ap-south-1': 
  awsRegistry: 602401143452.dkr.ecr.ap-south-1.amazonaws.com
  % elif values['awsPlatform']['region'] == 'ap-south-2': 
  awsRegistry: 900889452093.dkr.ecr.ap-south-2.amazonaws.com
  % elif values['awsPlatform']['region'] == 'eu-central-1': 
  awsRegistry: 602401143452.dkr.ecr.eu-central-1.amazonaws.com
  % elif values['awsPlatform']['region'] == 'eu-central-2': 
  awsRegistry: 900612956339.dkr.ecr.eu-central-2.amazonaws.com  
  % endif  
    
