

# cnpg-postgres-platform

<!-- BRIEF -->
This module is responsible for deployment of [CNPG Operator](https://cloudnative-pg.io/documentation/current/).

Depends on modules:
- [platform-core](/modules/101-platform-core/README.md) from which *platform* Service Account is used

Provides:
- CNPG Operator deployment
- Configuration of postgres cluster CRDs (postgresql.cnpg.io/v1)

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
			<td style="width: 300px;" id="cnpgPostgresPlatform--cloudnative-pg">cnpgPostgresPlatform.cloudnative-pg</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>additionalEnv:
    - name: EXPIRING_CHECK_THRESHOLD
      value: "30"
crds:
    create: false
enabled: true
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/cloudnative-pg/cloudnative-pg
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

Configuration for CNPG operator helm chart. See https://github.com/cloudnative-pg/charts/tree/main/charts/cloudnative-pg for API reference.

</div>
</td>
		</tr>
	</tbody>
</table>

