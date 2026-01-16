

# kyverno-platform

<!-- BRIEF -->
This module provides https://kyverno.io/ policy engine platform service.

Depends on modules:
- no dependencies

Provides:
- Kyverno Helm Deployment, see https://github.com/kyverno/kyverno/blob/main/charts/kyverno/README.md
- Kyverno Policies, see https://github.com/kyverno/kyverno/blob/main/charts/kyverno-policies/README.md

This module is deployed to namespace `kyverno`, not `platform`. This is needed to allow `kyverno` namespace exclusion, see https://kyverno.io/docs/installation/#security-vs-operability
As side effect, this module can't be automatically deleted by addon-operator, so manual "helm unistall" will be needed in order to uninstall it.

Customizations:
- 'webhooksCleanup' image is replaced from 'registry.k8s.io/kubectl' to 'platform/platform-k8s-tools-minimal:1.3.3'
- 'test' image is replaced from 'busybox' to 'platform/platform-k8s-tools-minimal:1.3.3'

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
			<td style="width: 300px;" id="kyvernoPlatform--kyverno">kyvernoPlatform.kyverno</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>crds:
    install: false
    migration:
        enabled: false
global:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    tolerations:
        - effect: NoSchedule
          key: dedicated-nodes
          operator: Equal
          value: platform-masters
        - effect: NoSchedule
          key: CriticalAddonsOnly
          operator: Exists
policyExceptions:
    enabled: false
    namespace: ""
test:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc
webhooksCleanup:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc</code></pre>
</td>
			<td><div>

Configuration for underlying Kyverno helm-chart. See https://github.com/kyverno/kyverno/blob/main/charts/kyverno/README.md

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kyvernoPlatform--kyverno-policies">kyvernoPlatform.kyverno-policies</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>see child items doc</code></pre>
</td>
			<td><div>

Configuration for underlying Kyverno Policies helm-chart. See https://github.com/kyverno/kyverno/blob/main/charts/kyverno-policies/README.md

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kyvernoPlatform--kyverno-policies--enabled">kyvernoPlatform.kyverno-policies.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Toggle to enable Kyverno Policies chart deployment

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kyvernoPlatform--kyverno-policies--podSecuritySeverity">kyvernoPlatform.kyverno-policies.podSecuritySeverity</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>medium</code></pre>
</td>
			<td><div>

Pod Security Standard (`low`, `medium`, `high`).

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kyvernoPlatform--kyverno-policies--podSecurityStandard">kyvernoPlatform.kyverno-policies.podSecurityStandard</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>baseline</code></pre>
</td>
			<td><div>

Pod Security Standard profile (`baseline`, `restricted`, `privileged`, `custom`). For more info https://kyverno.io/policies/pod-security.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kyvernoPlatform--kyverno--crds--install">kyvernoPlatform.kyverno.crds.install</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

We deploy all CRDs under /resources folder.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kyvernoPlatform--kyverno--crds--migration--enabled">kyvernoPlatform.kyverno.crds.migration.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable CRDs migration using helm post upgrade hook

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kyvernoPlatform--kyverno--global--image--registry">kyvernoPlatform.kyverno.global.image.registry</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>platform.artifactory.qvantel.net/k8s-platform-1-2-0</code></pre>
</td>
			<td><div>

Global value that allows to set a single image registry across all deployments. When set, it will override any values set under `.image.registry` across the chart.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kyvernoPlatform--kyverno--policyExceptions--enabled">kyvernoPlatform.kyverno.policyExceptions.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enables the feature

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kyvernoPlatform--kyverno--policyExceptions--namespace">kyvernoPlatform.kyverno.policyExceptions.namespace</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>""</code></pre>
</td>
			<td><div>

Restrict policy exceptions to a single namespace Set to "*" to allow exceptions in all namespaces

</div>
</td>
		</tr>
	</tbody>
</table>

