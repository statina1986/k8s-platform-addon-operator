

# rabbitmq-platform

<!-- BRIEF -->
This module deploys [Bitnami's Rabbitmq](https://artifacthub.io/packages/helm/bitnami/rabbitmq/15.2.4) chart, providing RabbitMQ version 4.0.5.

[Upstream values.yaml with comments](https://github.com/bitnami/charts/blob/main/bitnami/rabbitmq/values.yaml)

Dependencies:
 - [Vault](../140-vault-platform/)
    - Through [vault-credentials-inject.sh](./hooks/vault-credentials-inject.sh)

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
			<td style="width: 300px;" id="rabbitmqPlatform--rabbitmq--customReadinessProbe">rabbitmqPlatform.rabbitmq.customReadinessProbe</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>exec:
    command:
        - sh
        - -ec
        - rabbitmq-diagnostics -q ping
timeoutSeconds: 10</code></pre>
</td>
			<td><div>

More relaxed readiness probe to prevent a deadlock when restarting after an abrupt stop. This is because rabbitmq tries to sync with its peers before becoming fully functional, while Kubernetes OrderedReady policy only starts the next pod once first one is considered ready.  Documentation suggests running the Parallel pod management policy, but it is only feasible for existing clusters - new deployments need to be ran with OrderedReady to add new cluster members one by one. In addition adjusting podManagementPolicy is not allowed on the fly, forcing recreating the sateful set.  However, since liveness probe defaults to curling /api/health/checks/virtual-hosts, a relaxed readiness probe shouldn't lead to false positives concerning pod health.  [RabbitMQ documentation](https://www.rabbitmq.com/docs/clustering#restarting-readiness-probes) [Chart values documentation](https://github.com/bitnami/charts/blob/main/bitnami/rabbitmq/values.yaml#L684-L695) [StackOverflow thread with a comment from RMQ developer](https://stackoverflow.com/questions/60407082/rabbit-mq-error-while-waiting-for-mnesia-tables/78439528#78439528)

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="rabbitmqPlatform--rabbitmq--extraPlugins">rabbitmqPlatform.rabbitmq.extraPlugins</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>rabbitmq_auth_backend_ldap rabbitmq_web_stomp rabbitmq_stomp</code></pre>
</td>
			<td><div>

Enabled rabbitmq extra plugins

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="rabbitmqPlatform--rabbitmq--global">rabbitmqPlatform.rabbitmq.global</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>security:
    allowInsecureImages: true</code></pre>
</td>
			<td><div>

Has to be set because Bitnami considers mirror registries insecure

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="rabbitmqPlatform--rabbitmq--plugins">rabbitmqPlatform.rabbitmq.plugins</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>rabbitmq_management rabbitmq_peer_discovery_k8s</code></pre>
</td>
			<td><div>

Enabled rabbitmq plugins

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="rabbitmqPlatform--rabbitmq--replicaCount">rabbitmqPlatform.rabbitmq.replicaCount</td>
			<td>int</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>3</code></pre>
</td>
			<td><div>

Number of replicas - Default is one for development profile, three for anything else.

</div>
</td>
		</tr>
	</tbody>
</table>

