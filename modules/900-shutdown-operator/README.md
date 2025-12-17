

# shutdown-operator

<!-- BRIEF -->
This module deploys the shutdown-addon-operator, that is used to manage the cluster scaledown / up separate from the main addon-operator.
The main resources for this module are deployed under the k8s-platform chart /templates:

Depends on:
- platform-shutdown namespace needs to exist in the cluster before this module is enabled

Provides:
- platform-shutdown serviceaccount and needed RBAC
- shutdown-operator deployment
- shutdown-operator configmap

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
			<td style="width: 300px;" id="shutdownOperator--turndown--enabled">shutdownOperator.turndown.enabled</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>"false"</code></pre>
</td>
			<td><div>

Enables the clusterturndown feature

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="shutdownOperator--turndown--scaledownSchedule">shutdownOperator.turndown.scaledownSchedule</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>0 5 31 2 *</code></pre>
</td>
			<td><div>

Scheduled time when cluster will be scaled down

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="shutdownOperator--turndown--scaleupSchedule">shutdownOperator.turndown.scaleupSchedule</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>0 5 31 2 *</code></pre>
</td>
			<td><div>

Scheduled time when cluster will be scaled up

</div>
</td>
		</tr>
	</tbody>
</table>

