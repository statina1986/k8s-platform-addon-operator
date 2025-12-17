

# kasope-platform


<!-- BRIEF -->
`kasope-platform` module is responsible for deployment of [K8ssandra Operator](https://docs.k8ssandra.io/components/k8ssandra-operator/) in the cluster.

Dependencies:
- Kubernetes version 1.26+
- [cert-manager](https://stash.qvantel.net/projects/CP/repos/k8s-platform-addon-operator/browse/modules/101-cert-platform/README.md) for K8ssandra Operator Webhook server cert

Provides:
- K8ssandra Operator for multi-cluster support
- Cass Operator for Cassandra cluster management
- Automated secret creation for connection to Platform MinIO


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
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator">kasopePlatform.k8ssandra-operator</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cass-operator:
    admissionWebhooks:
        enabled: false
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    serviceAccount:
        create: false
        name: platform
cleaner:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
disableCrdUpgraderJob: true
enabled: true
global:
    clusterScoped: true
    imageConfig:
        defaults:
            registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        images:
            config-builder:
                name: cass-config-builder
                repository: datastax
                tag: 1.0-ubi8
            k8ssandra-client:
                name: k8ssandra-client
                repository: k8ssandra
                tag: v0.8.3
            medusa:
                name: medusa
                repository: k8ssandra
                tag: 0.25.1
            reaper:
                name: cassandra-reaper
                repository: thelastpickle
                tag: 4.0.0
            system-logger:
                name: system-logger
                repository: k8ssandra
                tag: v1.27.1
        types:
            cassandra:
                name: cass-management-api
                repository: k8ssandra
                suffix: -ubi8
image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
serviceAccount:
    create: false
    name: platform</code></pre>
</td>
			<td><div>

Configuration for underlying k8ssandra-operator helm-chart. See https://github.com/k8ssandra/k8ssandra-operator/tree/main/charts/k8ssandra-operator

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator--cass-operator">kasopePlatform.k8ssandra-operator.cass-operator</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>admissionWebhooks:
    enabled: false
image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
serviceAccount:
    create: false
    name: platform</code></pre>
</td>
			<td><div>

Configuration for underlying cass-operator helm-chart. See https://github.com/k8ssandra/k8ssandra/tree/main/charts/cass-operator

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator--disableCrdUpgraderJob">kasopePlatform.k8ssandra-operator.disableCrdUpgraderJob</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

CRD Upgrader is disabled by default as we manage CRDs ourselves

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator--enabled">kasopePlatform.k8ssandra-operator.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

In clusters where we can't or won't deploy operators, then this can be set to false.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kasopePlatform--k8ssandra-operator--global--imageConfig">kasopePlatform.k8ssandra-operator.global.imageConfig</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>defaults:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
images:
    config-builder:
        name: cass-config-builder
        repository: datastax
        tag: 1.0-ubi8
    k8ssandra-client:
        name: k8ssandra-client
        repository: k8ssandra
        tag: v0.8.3
    medusa:
        name: medusa
        repository: k8ssandra
        tag: 0.25.1
    reaper:
        name: cassandra-reaper
        repository: thelastpickle
        tag: 4.0.0
    system-logger:
        name: system-logger
        repository: k8ssandra
        tag: v1.27.1
types:
    cassandra:
        name: cass-management-api
        repository: k8ssandra
        suffix: -ubi8</code></pre>
</td>
			<td><div>

Setting new imageConfig from k8ssandra-operator 1.27.0

</div>
</td>
		</tr>
	</tbody>
</table>

