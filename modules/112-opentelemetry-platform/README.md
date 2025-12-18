

# opentelemetry-platform

<!-- BRIEF -->
This module is responsible for deployment of[opentelemetry-operator](https://opentelemetry.io/docs) in the cluster.
To be able to manage automatic instrumentation, the Operator needs to be configured to know what pods to instrument and which automatic instrumentation to use for those pods. This is done by the [instrumentation CRD](https://opentelemetry.io/docs/platforms/kubernetes/operator/automatic/)


Depends on modules:
- `cert-platform` needed for opentelemetry-operator because it uses Kubernetes admission webhooks, and webhooks require TLS certificates.
- `monitoring-platform` which contains Alloy collector and metrics/traces backends.

Used helm-charts:
- `opentelemetry-operator`

Provides:
- `opentelemetry-operator` deployment



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
			<td style="width: 300px;" id="opentelemetryPlatform--opentelemetry-operator">opentelemetryPlatform.opentelemetry-operator</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
kubeRBACProxy:
    enabled: true
    image:
        repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/brancz/kube-rbac-proxy
        tag: v0.19.1
manager:
    autoInstrumentationImage:
        apacheHttpd:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/otel-operator/autoinstrumentation-apache-httpd
            tag: 1.0.4
        dotnet:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/otel-operator/autoinstrumentation-dotnet
            tag: 1.12.0
        java:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/otel-operator/autoinstrumentation-java
            tag: 2.18.1
        nodejs:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/otel-operator/autoinstrumentation-nodejs
            tag: 0.62.0
        python:
            repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/otel-operator/autoinstrumentation-python
            tag: 0.57b0
    collectorImage:
        repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s
        tag: 0.131.1
    image:
        repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/otel-operator/open-telemetry/opentelemetry-operator/opentelemetry-operator
        tag: v0.93.0
    serviceMonitor:
        enabled: true
        extraLabels:
            release: monitoring-platform</code></pre>
</td>
			<td><div>

Configuration for OpenTelemetry Operator helm chart. See https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-demo

</div>
</td>
		</tr>
	</tbody>
</table>

