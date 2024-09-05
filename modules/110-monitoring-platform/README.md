# monitoring-platform module
This module is responsible for deployment of Qvantel Monitoring Stack which is based on Prometheus and Grafana

Dependencies:
- Kubernetes version 1.26+


Customizations:
- 'initChownData' image is replaced from 'busybox' to 'ubi9/ubi-minimal'
- 'grafana-plugins' image to load Grafana Plugins in different architectures for air/non air gapped environments
