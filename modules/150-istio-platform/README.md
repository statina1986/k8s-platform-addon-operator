# istio-platform module
This module is responsible for deployment of [Istio](https://github.com/istio/istio) control plane the cluster

Depends on modules:
- [cert-platform](/modules/110-cert-platform/README.md) which is needed to established vault certificates

Provides:
- Istio Control Plane

### Default configuration
Here are important default configs established:
* HTTP Retries are disable by default, because they are not safe for Qvantel products
* Access Logging for Ingress solution is configured with JSON format including Qvantel specifics like X-Trace-Token
