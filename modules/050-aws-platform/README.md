

# aws-platform

<!-- BRIEF -->
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

<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;" id="awsPlatform--apiServerEndpoint">awsPlatform.apiServerEndpoint</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>null</code></pre>
</td>
			<td><div>

**Required.** EKS API server endpoint.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--aws-ebs-csi-driver">awsPlatform.aws-ebs-csi-driver</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>controller:
    extraVolumeTags: {}
    serviceAccount:
        create: false
        name: platform
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/ebs-csi-driver/aws-ebs-csi-driver
node:
    enableWindows: false
    serviceAccount:
        create: false
        name: platform
sidecars:
    attacher:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/csi-components/csi-attacher
    livenessProbe:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/csi-components/livenessprobe
    nodeDriverRegistrar:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/csi-components/csi-node-driver-registrar
    provisioner:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/csi-components/csi-provisioner
    resizer:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/csi-components/csi-resizer
    snapshotter:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/csi-components/csi-snapshotter
    volumemodifier:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/ebs-csi-driver/volume-modifier-for-k8s
storageClasses:
    - allowVolumeExpansion: true
      annotations:
        storageclass.kubernetes.io/is-default-class: "true"
      name: gp3
      parameters:
        tagSpecification_name: Name=some-cluster-{{ .PVCName }}
        type: gp3
      reclaimPolicy: Delete
      volumeBindingMode: WaitForFirstConsumer
    - allowVolumeExpansion: true
      name: st1
      parameters:
        tagSpecification_name: Name=some-cluster-{{ .PVCName }}
        type: st1
      reclaimPolicy: Delete
      volumeBindingMode: WaitForFirstConsumer</code></pre>
</td>
			<td><div>

Configuration for underlying aws-ebs-csi-driver helm-chart. See https://github.com/kubernetes-sigs/aws-ebs-csi-driver for details.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--aws-ebs-csi-driver-enabled">awsPlatform.aws-ebs-csi-driver-enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Deploy aws-ebs-csi-driver helm-chart.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--aws-efs-csi-driver">awsPlatform.aws-efs-csi-driver</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>controller:
    serviceAccount:
        create: false
        name: platform
    tolerations:
        - effect: NoSchedule
          key: dedicated-nodes
          operator: Equal
          value: platform-masters
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/amazon/aws-efs-csi-driver
node:
    serviceAccount:
        create: false
        name: platform
sidecars:
    csiProvisioner:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/csi-components/csi-provisioner
    livenessProbe:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/csi-components/livenessprobe
    nodeDriverRegistrar:
        image:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/csi-components/csi-node-driver-registrar
storageClasses:
    - mountOptions:
        - tls
      name: efs-sc
      parameters:
        basePath: /dynamic_provisioning
        directoryPerms: "700"
        fileSystemId: SYSTEM_EFS_VALUE_HERE
        gid: "0"
        provisioningMode: efs-ap
        uid: "0"
      reclaimPolicy: Delete
      volumeBindingMode: Immediate</code></pre>
</td>
			<td><div>

Configuration for underlying aws-efs-csi-driver helm-chart. See https://github.com/kubernetes-sigs/aws-efs-csi-driver for details.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--aws-efs-csi-driver-enabled">awsPlatform.aws-efs-csi-driver-enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Deploy aws-efs-csi-driver helm-chart.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--aws-load-balancer-controller">awsPlatform.aws-load-balancer-controller</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>clusterName: some-cluster
defaultTags: {}
serviceAccount:
    create: false
    name: platform
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

Configuration for underlying aws-load-balancer-controller helm-chart. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/README.md#configuration for details.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--aws-load-balancer-controller-enabled">awsPlatform.aws-load-balancer-controller-enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Deploy aws-load-balancer-controller helm-chart.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--aws-vpc-cni">awsPlatform.aws-vpc-cni</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>eniConfig:
    region: eu-central-1
env:
    ENABLE_PREFIX_DELEGATION: "true"
image:
    account: "602401143452"
    region: eu-central-1
init:
    image:
        account: "602401143452"
        region: eu-central-1
nodeAgent:
    image:
        account: "602401143452"
        region: eu-central-1</code></pre>
</td>
			<td><div>

Configuration for underlying aws-vpc-cni helm-chart. See https://github.com/aws/amazon-vpc-cni-k8s/tree/master/charts/aws-vpc-cni#configuration for details.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--aws-vpc-cni-enabled">awsPlatform.aws-vpc-cni-enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Deploy aws-vpc-cni helm-chart.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--awsKubeProxy">awsPlatform.awsKubeProxy</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>image: v1.28.15-minimal-eksbuild.31</code></pre>
</td>
			<td><div>

Configuration for EKS kube-proxy.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--awsKubeProxy--image">awsPlatform.awsKubeProxy.image</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>v1.28.15-minimal-eksbuild.31</code></pre>
</td>
			<td><div>

Mako templating to match kube-proxy image to recommended as of 16th of Dec 2025 https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html#managing-kube-proxy-images

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--awsKubeProxyEnabled">awsPlatform.awsKubeProxyEnabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Deploy EKS kube-proxy.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--awsRegistry">awsPlatform.awsRegistry</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>602401143452.dkr.ecr.eu-central-1.amazonaws.com</code></pre>
</td>
			<td><div>

ECR registry for AWS images. By default is automatically assigned based on configured `region`

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--clusterName">awsPlatform.clusterName</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>some-cluster</code></pre>
</td>
			<td><div>

EKS cluster name. Defaults to the name from `global.clusterName`

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--region">awsPlatform.region</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>eu-central-1</code></pre>
</td>
			<td><div>

**Required.** AWS Region where cluster is deployed.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="awsPlatform--tags">awsPlatform.tags</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>null</code></pre>
</td>
			<td><div>

**Required.** Default tags to be added for AWS Resources provisioned by this module (loadbalancers, ebs volumes, etc). If you do not want to add tags, provide `{}`.

</div>
</td>
		</tr>
	</tbody>
</table>

