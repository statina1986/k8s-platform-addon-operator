

# velero-platform

<!-- BRIEF -->
This module is responsible for deployment of [Velero](https://cert-manager.io/docs/)

Depends on modules:
- no dependencies

Used helm-charts:
- Velero : v11.1.1
​

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
			<td style="width: 300px;" id="veleroPlatform--velero">veleroPlatform.velero</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>configuration:
    defaultSnapshotMoveData: true
    features: EnableCSI
credentials:
    useSecret: false
deployNodeAgent: true
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/velero/velero
    tag: v1.17.0
initContainers:
    - image: platform.artifactory.qvantel.net/k8s-platform-1-2-0/velero/velero-plugin-for-aws:v1.13.0
      name: velero-plugin-for-aws
      volumeMounts:
        - mountPath: /target
          name: plugins
serviceAccount:
    server:
        create: false
        name: platform</code></pre>
</td>
			<td><div>

Configuration for underlying velero helm-chart. See https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero#configuration

</div>
</td>
		</tr>
	</tbody>
</table>

