

# opentelemetry-platform

<!-- BRIEF -->
This module is responsible for deployment of[opentelemetry-operator](https://opentelemetry.io/docs) in the cluster.
To be able to manage automatic instrumentation, the Operator needs to be configured to know what pods to instrument and which automatic instrumentation to use for those pods. This is done by the [instrumentation CRD](https://opentelemetry.io/docs/platforms/kubernetes/operator/automatic/)


Depends on modules:
- cert-platform needed for opentelemetry-operator because it uses Kubernetes admission webhooks, and webhooks require TLS certificates.
- grafana Alloy to send metrics and traces to the collector.

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
	</tbody>
</table>

