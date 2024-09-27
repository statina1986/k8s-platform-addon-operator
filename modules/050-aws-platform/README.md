# aws-platform

This module configures needed plugins and services to run Qvantel K8S Platfrom on AWS EKS clusters and within AWS Cloud

Depends on modules:
- no dependencies

Used helm-charts:
- `aws-ebs-csi-driver`
- `aws-efs-csi-driver`
- `aws-load-balancer-controller`
- `aws-vpc-cni`

Provides:
- `aws-ebs-csi-driver` deployment
- `aws-efs-csi-driver` deployment
- `aws-load-balancer-controller` deployment
- `aws-vpc-cni` deployment
- `kube-proxy` deployment
- AWS resource tagging
- EKS clusters scaledown/scaleup support

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| awsPlatform.apiServerEndpoint | string | `nil` | **Required.** EKS API server endpoint. |
| awsPlatform.aws-ebs-csi-driver | object | `{"controller":{"extraVolumeTags":{},"serviceAccount":{"create":false,"name":"platform"}},"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/ebs-csi-driver/aws-ebs-csi-driver"},"node":{"serviceAccount":{"create":false,"name":"platform"}},"sidecars":{"attacher":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/kubernetes-csi/external-attacher"}},"livenessProbe":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/kubernetes-csi/livenessprobe"}},"nodeDriverRegistrar":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/kubernetes-csi/node-driver-registrar"}},"provisioner":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/kubernetes-csi/external-provisioner"}},"resizer":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/kubernetes-csi/external-resizer"}},"snapshotter":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/external-snapshotter/csi-snapshotter"}},"volumemodifier":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/ebs-csi-driver/volume-modifier-for-k8s"}}},"storageClasses":[{"allowVolumeExpansion":true,"annotations":{"storageclass.kubernetes.io/is-default-class":"true"},"name":"gp3","parameters":{"tagSpecification_name":"Name=some-cluster-{{ .PVCName }}","type":"gp3"},"reclaimPolicy":"Delete","volumeBindingMode":"WaitForFirstConsumer"}]}` | Configuration for underlying aws-ebs-csi-driver helm-chart. See https://github.com/kubernetes-sigs/aws-ebs-csi-driver for details. |
| awsPlatform.aws-ebs-csi-driver-enabled | bool | `false` | Deploy aws-ebs-csi-driver helm-chart. |
| awsPlatform.aws-efs-csi-driver | object | `{"controller":{"serviceAccount":{"create":false,"name":"platform"},"tolerations":[{"effect":"NoSchedule","key":"dedicated-nodes","operator":"Equal","value":"platform-masters"}]},"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/amazon/aws-efs-csi-driver"},"node":{"serviceAccount":{"create":false,"name":"platform"}},"sidecars":{"csiProvisioner":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/kubernetes-csi/external-provisioner"}},"livenessProbe":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/kubernetes-csi/livenessprobe"}},"nodeDriverRegistrar":{"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/kubernetes-csi/node-driver-registrar"}}},"storageClasses":[{"mountOptions":["tls"],"name":"efs-sc","parameters":{"basePath":"/dynamic_provisioning","directoryPerms":"700","fileSystemId":"SYSTEM_EFS_VALUE_HERE","gid":"0","provisioningMode":"efs-ap","uid":"0"},"reclaimPolicy":"Delete","volumeBindingMode":"Immediate"}]}` | Configuration for underlying aws-efs-csi-driver helm-chart. See https://github.com/kubernetes-sigs/aws-efs-csi-driver for details. |
| awsPlatform.aws-efs-csi-driver-enabled | bool | `false` | Deploy aws-efs-csi-driver helm-chart.  |
| awsPlatform.aws-load-balancer-controller | object | `{"clusterName":"some-cluster","defaultTags":{},"serviceAccount":{"create":false,"name":"platform"},"tolerations":[{"effect":"NoSchedule","key":"dedicated-nodes","operator":"Equal","value":"platform-masters"}]}` | Configuration for underlying aws-load-balancer-controller helm-chart. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/README.md#configuration for details. |
| awsPlatform.aws-load-balancer-controller-enabled | bool | `false` | Deploy aws-load-balancer-controller helm-chart.  |
| awsPlatform.aws-vpc-cni | object | `{"eniConfig":{"region":"eu-central-1"},"env":{"ENABLE_PREFIX_DELEGATION":"true"},"image":{"account":"602401143452","region":"eu-central-1"},"init":{"image":{"account":"602401143452","region":"eu-central-1"}},"nodeAgent":{"image":{"account":"602401143452","region":"eu-central-1"}}}` | Configuration for underlying aws-vpc-cni helm-chart. See https://github.com/aws/amazon-vpc-cni-k8s/tree/master/charts/aws-vpc-cni#configuration for details. |
| awsPlatform.aws-vpc-cni-enabled | bool | `false` | Deploy aws-vpc-cni helm-chart. |
| awsPlatform.awsKubeProxy | object | `{"image":"v1.25.16-minimal-eksbuild.1"}` | Configuration for EKS kube-proxy.  |
| awsPlatform.awsKubeProxyEnabled | bool | `false` | Deploy EKS kube-proxy. |
| awsPlatform.awsRegistry | string | `"602401143452.dkr.ecr.eu-central-1.amazonaws.com"` | ECR registry for AWS images. By default is automatically assigned based on configured `region` |
| awsPlatform.clusterName | string | `"some-cluster"` | EKS cluster name. Defaults to the name from `global.clusterName` |
| awsPlatform.region | string | `"eu-central-1"` | **Required.** AWS Region where cluster is deployed.  |
| awsPlatform.tags | string | `nil` | **Required.** Default tags to be added for AWS Resources provisioned by this module (loadbalancers, ebs volumes, etc). If you do not want to add tags, provide `{}`. |

