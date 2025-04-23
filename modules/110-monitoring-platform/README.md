

# monitoring-platform


This module configures needed plugins and services to run Qvantel K8S Platfrom on AWS EKS clusters and within AWS Cloud

Depends on modules:
- no dependencies

Used helm-charts:
- `kube-prometheus-stack`
- `prometheus-blackbox-exporter`
- `x509-certificate-exporter`
- `yet-another-cloudwatch-exporter`

Provides:
- `kube-prometheus-stack` deployment
- `prometheus-blackbox-exporter` deployment
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
	</tbody>
</table>

