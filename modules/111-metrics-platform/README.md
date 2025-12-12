

# metrics-platform

# metrics-platform module
This module is responsible for deployment of [metrics-server](https://github.com/kubernetes-sigs/metrics-server/) in the cluster

Depends on modules:
- no dependencies

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
			<td style="width: 300px;" id="metricsPlatform--metrics-server">metricsPlatform.metrics-server</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>addonResizer:
    image:
        repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/autoscaling/addon-resizer
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/metrics-server/metrics-server
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

Default configurations for metric platform

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="metricsPlatform--metrics-server--tolerations">metricsPlatform.metrics-server.tolerations</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- effect: NoSchedule
  key: dedicated-nodes
  operator: Equal
  value: platform-masters</code></pre>
</td>
			<td><div>

Tolerations if platform masters are enabled

</div>
</td>
		</tr>
	</tbody>
</table>

