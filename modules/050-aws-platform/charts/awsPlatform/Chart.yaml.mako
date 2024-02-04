apiVersion: v2
name: awsPlatform
version: 0.0.1
dependencies:
  - name: aws-load-balancer-controller
    version: "1.7.0"
    repository: https://aws.github.io/eks-charts
    condition: aws-load-balancer-controller-enabled
  - name: aws-efs-csi-driver
    version: "2.5.4"
    repository: https://kubernetes-sigs.github.io/aws-efs-csi-driver/
    condition: aws-efs-csi-driver-enabled
  - name: aws-ebs-csi-driver
    version: "2.27.0"
    repository: https://kubernetes-sigs.github.io/aws-ebs-csi-driver/
    condition: aws-ebs-csi-driver-enabled
  - name: aws-vpc-cni
    % if values['global']['kubernetesVersion'] in {'1.25','1.26','1.27','1.28','1.29'}: 
    version: "1.16.2"
    % endif
    repository: https://aws.github.io/eks-charts
    condition: aws-vpc-cni-enabled