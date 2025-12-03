

# redis-platform

# redis-platform module
This module is responsible for deployment of Redis (https://github.com/redis/redis)

Depends on modules:
- [vault-platform](https://stash.qvantel.net/projects/CP/repos/k8s-platform-addon-operator/browse/modules/140-vault-platform/README.md) for backing up Redis credentials to Vault

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
			<td style="width: 300px;" id="redisPlatform--redis--architecture">redisPlatform.redis.architecture</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>replication</code></pre>
</td>
			<td><div>

Architecture type

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--auth">redisPlatform.redis.auth</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
sentinel: true</code></pre>
</td>
			<td><div>

Auth configurations

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--commonConfiguration">redisPlatform.redis.commonConfiguration</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>|-
    # Enable AOF https://redis.io/topics/persistence#append-only-file
    appendonly no
    # Enable RDB persistence, AOF persistence already enabled.
    save 900 1
    save 300 10
    save 60 10000</code></pre>
</td>
			<td><div>

Common configurations

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--global">redisPlatform.redis.global</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>security:
    allowInsecureImages: true</code></pre>
</td>
			<td><div>

Global configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--image">redisPlatform.redis.image</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
repository: platform/bitnami-redis
tag: 8.2.2</code></pre>
</td>
			<td><div>

Image configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--kubectl">redisPlatform.redis.kubectl</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    repository: platform/platform-k8s-tools-minimal
    tag: 1.3.3_202509080945_master_90384dcc</code></pre>
</td>
			<td><div>

Kubectl configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--master">redisPlatform.redis.master</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>persistence:
    enabled: true
    size: 8Gi
    storageClass: ""
resources:
    limits: {}
    requests: {}
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

Master configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--metrics">redisPlatform.redis.metrics</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    repository: platform/bitnami-redis-exporter
    tag: 1.79.0</code></pre>
</td>
			<td><div>

Metrics Configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--rbac">redisPlatform.redis.rbac</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>create: true</code></pre>
</td>
			<td><div>

RBAC configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--replica">redisPlatform.redis.replica</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>automountServiceAccountToken: true
persistence:
    enabled: true
    size: 8Gi
    storageClass: ""
replicaCount: 3
resources:
    limits: {}
    requests: {}
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

Replica configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--sysctl">redisPlatform.redis.sysctl</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    repository: platform/platform-k8s-tools-minimal
    tag: 1.3.3_202509080945_master_90384dcc</code></pre>
</td>
			<td><div>

Sysctl configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="redisPlatform--redis--volumePermissions">redisPlatform.redis.volumePermissions</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    repository: platform/platform-k8s-tools-minimal
    tag: 1.3.3_202509080945_master_90384dcc</code></pre>
</td>
			<td><div>

Volume configuration

</div>
</td>
		</tr>
	</tbody>
</table>

