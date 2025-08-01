

# mongodb-platform

This module deploys [Bitnami's MongoDB](https://artifacthub.io/packages/helm/bitnami/mongodb/15.6.12) chart.

[Upstream values.yaml with comments](https://github.com/bitnami/charts/blob/main/bitnami/mongodb/values.yaml).

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
			<td style="width: 300px;" id="mongodbPlatform--mongodb--architecture">mongodbPlatform.mongodb.architecture</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>replicaset</code></pre>
</td>
			<td><div>

Deploying as replicaset as opposed to standalone, resulting in an arbiter and two instances, primary and secondary, which may swap.

</div>
</td>
		</tr>
	</tbody>
</table>

