
# K8S Platform Services

This repo contains implementation of **K8S Platform Services** based on the [addon-operator](https://github.com/flant/addon-operator)

>
> Please check [addon-operator](https://github.com/flant/addon-operator) documentation first
> 

## Available Modules
- [platform-core](modules/001-platform-core/README.md) for core parts of platform
- [aws-platform](modules/050-aws-platform/README.md) configures needed plugins and services to manage Qvantel K8S Platform on AWS Cloud
- [cert-platform](modules/101-cert-platform/README.md) for certificate management with **cert-manager**
- [monitoring-platform](modules/110-monitoring-platform/README.md) for Prometheus/Grafana monitoring stack
- [consul-platform](modules/130-consul-platform/README.md) for **consul** deployment
- [vault-platform](modules/140-vault-platform/README.md) for **vault** deployment and configuration via CRDs
- [istio-platform](modules/150-istio-platform/README.md) for **istio** control-plane deployment and configuration
- [istio-ingress](modules/151-istio-ingress/README.md) for **istio** Ingress Gateways deployment and configuration

## Modules Order
Modules are ordered alphanumerically based on their folder names. This is the order of the deployment.
Current conventions for naming:

* 000-010 - Reserved for core platform modules and features
* 010-100 - Infrastructure specific support modules, e.g. to support AWS cloud, GCP, Azure
* 100-199 - Core platform modules like *Vault* or *Cert-Manager*. Later modules usually depends on those.
* 200-299 - Data Bases engines and persistent storages like *Postgres*, *Cassandra*, *Redis*
* 300-399 - Platform Configuration Enablers like *qinstallers*. Usually provide additional management capabilities for services defined on previous levels
* 400-999 - those are not well-defined yet and can be used freely

## Testing the platform
It is easy to start with this platform both on local and cloud k8s cluster.
Easiest way is to build platform image and chart locally, push them to some repository (e.g. dockerhub) and deploy chart to the cluster via Helm.
You need on machine:
* Docker
* Kubectl
* Helm
* (Optional) Local k8s cluster, e.g. *minikube*,*k3d*,*Rancher Desktop*.

> When using local k8s cluster like *minikube* please be aware that most of Qvantel platform modules require at least 3 nodes (e.g. consul, vault, etc). Also some modules depends on cloud services (e.g. external-dns module) and will not be working as intended on local cluster. 

Clone repository to local machine (e.g. ~/qvantel/CP/k8s-platform-addon-operator)

Here is the deployment script which can be used to deploy platform from local machine to some k8s cluster:
```
#!/usr/bin/env bash
timestamp=$(date +%Y%m%d%H%M%S)

# Here we build the platform docker image locally as "local/addon-operator:$timestamp"
docker build -t "local/addon-operator:$timestamp" ~/qvantel/CP/k8s-platform-addon-operator

# Here we push builded image to minikube
minikube image load local/addon-operator:$timestamp

# This can be used to import builded image to k3d
# k3d image import -m direct local/addon-operator:$timestamp -c <your-cluster-name>

# Here we deploy platform helm chart with custom configuration from myvalues.yaml and also instruct it to use our locally built image
helm upgrade --install k8s-platform -n platform ~/qvantel/CP/k8s-platform-addon-operator/chart -f myvalues.yaml --set imageVersion=$timestamp,imageBase="local/addon-operator"
```
Of course kubectl/helm should point to correct cluster (e.g. local minikube or some cloud k8s)

Example myvalues.yaml file:
```
logLevel: "debug"
modulesConfig:
  certPlatformEnabled: "true"
  vaultPlatformEnabled: "true"
```

## Common Tasks

### Ensure required resources before module deployments
Sometimes some resources should be created before module deployment with helm. Most common things are **namespaces** and **CRDs**, which are not very well handled with current helm deployments. Yes, helm can deploy CRDs from /crds folder automatically, but if you have *kubernetes* hooks which reference those CRDs, they will not work. 

For this reason platform will deploy all resources from *resources* folder before module execution. It is possible to disable resources provisioning (e.g. when you don't have cluster-admin permissions and not able to provision CRDs anyway) with envvar ADDON_OPERATOR_DEPLOY_RESOURCES set to `false`.


### Dependencies subcharts
**addon-operator** has one significant limitation - it is hard to use external helm charts as dependencies (see https://github.com/flant/addon-operator/issues/153). Main issue is that values files in **addon-operator**  has special structure which is not compatible with subcharts values convention in Helm.

In order to overcome this it is possible to introduce empty subchart named as module name in camelCase as first dependency of the module. All external dependencies should be placed as subcharts of that empty subchart.
See example in module "130-cassandra-platform"

```
my-super-module/
    |--charts/
        |--mySuperModule/
            |--Chart.yaml (should define needed external dependencies)
    |--hooks/
        |--helm-update-dependencies.sh (hook which will download external dependencies required)
    |--Chart.yaml (has single dependency - "mySuperModule")
    |--values.yaml (now structure of values yaml is alligned with addon-operator)
```
