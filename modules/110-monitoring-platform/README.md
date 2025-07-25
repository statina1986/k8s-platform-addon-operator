

# monitoring-platform


This module configures Qvantel monitoring platform components to provide visibility to all that is happening inside the K8s cluster.
More detailed descriptions of each component can be found from [Platform Monitoring Overview](https://qvantel.atlassian.net/wiki/spaces/ICS/pages/1358177368/Monitoring+Overview)

Depends on modules:
- no dependencies

Used helm-charts:
- `alloy`
- `beyla`
- `kube-prometheus-stack`
- `prometheus-blackbox-exporter`
- `prometheus-consul-exporter`
- `tempo-distributed`
- `x509-certificate-exporter`
- `yet-another-cloudwatch-exporter`

Provides:
- `alloy` deployment
- `beyla` deployment
- `kube-prometheus-stack` deployment
- `prometheus-blackbox-exporter` deployment
- `prometheus-consul-exporter` deployment
- `tempo-distributed` deployment
- `x509-certificate-exporter` deployment
- `yet-another-cloudwatch-exporter` deployment


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
			<td style="width: 300px;" id="monitoringPlatform--alertManagerHighAvailability">monitoringPlatform.alertManagerHighAvailability</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

If enabled, configures alertmanager with 3 replicas and other HA parameters

</div>
</td>
		</tr>
	</tbody>
</table>

