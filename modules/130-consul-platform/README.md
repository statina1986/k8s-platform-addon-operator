

# consul-platform

<!-- BRIEF -->
This module is responsible for deployment of [Consul](https://www.consul.io/) in the cluster

Depends on modules:
- no dependencies

Provides:
- Consul deployment
- Consul DNS service resolution
- Consul catalog synchronization with K8S services
- Consul UI

Consul is available at:
- consul.service.consul
- consul-platform-consul-server.platform.svc

Consul UI is available at:
- consul-platform-consul-ui.platform.svc

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
			<td style="width: 300px;" id="consulPlatform--consul--syncCatalog">consulPlatform.consul.syncCatalog</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>addK8SNamespaceSuffix: false
enabled: true
k8sAllowNamespaces:
    - qvantel
k8sPrefix: null
nodePortSyncType: InternalOnly
resources:
    limits:
        cpu: "100"
        memory: 250Mi
    requests:
        cpu: 50m
        memory: 50Mi
toK8S: false</code></pre>
</td>
			<td><div>

Consul Sync Catalog configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--consul--syncCatalog--k8sAllowNamespaces">consulPlatform.consul.syncCatalog.k8sAllowNamespaces</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- qvantel</code></pre>
</td>
			<td><div>

Sync Catalog is restricted to apps namespace by default since platform 1.3.0

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--serviceSyncForClusterIP--enabled">consulPlatform.serviceSyncForClusterIP.enabled</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>"true"</code></pre>
</td>
			<td><div>

Enables services sync to Consul with ClusterIPs. Instead of 'original' Hashicorp services sync in this case ClusterIPs will be registered in Consul instead of individual pod IPs. Enabled by default since platform 1.3.0

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--serviceSyncForClusterIP--namespaceSelector">consulPlatform.serviceSyncForClusterIP.namespaceSelector</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - platform</code></pre>
</td>
			<td><div>

Selector for namespaces from which sync services, restricted to platform namespace by default since platform 1.3.0

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--serviceSyncForClusterIP--prefix">consulPlatform.serviceSyncForClusterIP.prefix</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>""</code></pre>
</td>
			<td><div>

Optional prefix for service names registered to Consul.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--serviceSyncForClusterIP--purgeClusterIPConsulSyncServicesOnStartup">consulPlatform.serviceSyncForClusterIP.purgeClusterIPConsulSyncServicesOnStartup</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>"false"</code></pre>
</td>
			<td><div>

Purge services in Consul from ClusterIP services sync

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--serviceSyncForClusterIP--purgeHashicorpConsulSyncServicesOnStartup">consulPlatform.serviceSyncForClusterIP.purgeHashicorpConsulSyncServicesOnStartup</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>"false"</code></pre>
</td>
			<td><div>

Purge services in Consul from Hashicorp services sync

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--serviceSyncForClusterIP--schedule">consulPlatform.serviceSyncForClusterIP.schedule</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>'*/5 * * * *'</code></pre>
</td>
			<td><div>

Schedule for reconciliation. Default is "*/5 * * * *" - so every 5 minutes.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--updateCoreDns">consulPlatform.updateCoreDns</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>configmapName: coredns
configmapNamespace: kube-system
enabled: "false"</code></pre>
</td>
			<td><div>

Configuration for Consul DNS service discovery

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--updateCoreDns--configmapName">consulPlatform.updateCoreDns.configmapName</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>coredns</code></pre>
</td>
			<td><div>

CoreDNS configmap to update with Consul DNS entries  

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--updateCoreDns--configmapNamespace">consulPlatform.updateCoreDns.configmapNamespace</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>kube-system</code></pre>
</td>
			<td><div>

CoreDNS configmap namespace to update with Consul DNS entries

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="consulPlatform--updateCoreDns--enabled">consulPlatform.updateCoreDns.enabled</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>"false"</code></pre>
</td>
			<td><div>

Consul DNS service discovery is disabled by default since platform 1.2.0

</div>
</td>
		</tr>
	</tbody>
</table>

 