

# rancher-platform

rancher-platform module

<!-- BRIEF -->
This module is created for Rancher installations

Provides: Rancher management cluster

For air-gapped installations please follow the rancher air-gapped installation guide:

https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/other-installation-methods/air-gapped-helm-cli-install

Greater list of helm values can be found from:
https://ranchermanager.docs.rancher.com/v2.9/getting-started/installation-and-upgrade/installation-references/helm-chart-options#advanced-options

Dependencies:
 - [cert-manager](../101-cert-platform/)

Known issues:
  - configuration for older psp might need to be set in the values file due to older charts residing in the module

### If needed configuration to bypass psp check
  ```
    rancher:
      global:
        cattle:
          psp:
            enabled: false
  ```

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
			<td style="width: 300px;" id="rancherHelmVersion">rancherHelmVersion</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>2.9.2</code></pre>
</td>
			<td><div>

We provide multiple versions of the rancher with same module this can be set to supported version

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="rancherPlatform">rancherPlatform</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>rancher:
    hostname: ""
    ingress:
        enabled: false
    privateCA: false
    rancherImage: platform.artifactory.qvantel.net/k8s-platform-1-2-0/rancher/rancher
    systemDefaultRegistry: platform.artifactory.qvantel.net/k8s-platform-1-2-0</code></pre>
</td>
			<td><div>

Default rancher configurations

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="rancherPlatform--rancher--hostname">rancherPlatform.rancher.hostname</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>""</code></pre>
</td>
			<td><div>

Hostname is required

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="rancherPlatform--rancher--ingress">rancherPlatform.rancher.ingress</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false</code></pre>
</td>
			<td><div>

Ingress set to false due to Istio being prefered

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="rancherPlatform--rancher--privateCA">rancherPlatform.rancher.privateCA</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Private Ca set to false by default

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="rancherPlatformNamespace">rancherPlatformNamespace</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cattle-system</code></pre>
</td>
			<td><div>

Rancher uses different default namespace from normal platform

</div>
</td>
		</tr>
	</tbody>
</table>

