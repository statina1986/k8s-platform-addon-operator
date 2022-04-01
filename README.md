
# K8S Platform Services

This repo conatins implementation of **K8S Platform Services** based on the [addon-operator](https://github.com/flant/addon-operator)

>
> Please check [addon-operator](https://github.com/flant/addon-operator) documentation first
> 


## Available Modules

- [cert-platform](modules/110-cert-platform/README.md) for certificate management with **cert-manager**
- [vault-platform](modules/140-vault-platform/README.md) for **vault** deployment

## Modules Order

Modules are ordered alphanumerically based on their folder names. This is the order of the deployment.
Current conventions for naming:

* 000-099 - reserverd
* 100-199 - Core platform modules like *Vault* or *Consul*. Later modules ussually depends on those.
* 200-299 - Data Bases engines and persistent storages like *Postgres*, *Cassandra*, *Redis*
* 300-399 - Platform Configuration Enablers like *qinstallers* or *vault-configuration*. Usually provide additional management capabilities for services defined on previous levels
* 400-999 those are not well-defined yet and can be used freely

## Testing the platform
It is easy to start with this platform both on local and cloud k8s cluster.
Easiest way is to build platfrom image and chart locally, push them to some repository (e.g. dockerhub) and deploy chart to the cluster via Helm.
You need on machine:
* Docker
* Kubectl
* Helm
* (Optional) Local k8s cluster, e.g. *minikube*.

> When using local k8s cluster like *minikube* please be aware that most of Qvantel platform modules require at least 3 nodes (e.g. consul, vault, etc). Also some modules depends on cloud services (e.g. external-dns module) and will not be working as intendent on local cluster. 

Clone repository to local machine (e.g. ~/qvantel/CP/k8s-platform-addon-operator)

Here is the deployment script which can be used to deploy platform from local machine to some k8s cluster:
```
#!/usr/bin/env bash
timestamp=$(date +%Y%m%d%H%M%S)

# Here we build the platform docker image localy as "sashaozz/addon-operator:$timestamp"
docker build -t "sashaozz/addon-operator:$timestamp" ~/qvantel/CP/k8s-platform-addon-operator

# Here we push builded image to dockerhub registry
docker push sashaozz/addon-operator:$timestamp

# Here we deploy platform helm chart with custom configuration from  myvalues.yaml
helm upgrade --install --create-namespace k8s-platform -n platform-modules ~/qvantel/CP/k8s-platform-addon-operator/chart -f myvalues.yaml --set imageVersion=$timestamp
```
Of course kubectl/helm should point to correct cluster (e.g. local minikube or some cloud k8s)

Example myvalues.yaml file:
```
imageBase: "sashaozz/addon-operator"
logLevel: "debug"
modulesConfig:
  certPlatformEnabled: "true"
  vaultPlatformEnabled: "true"
```

## Common Tasks

### Ensure required resources before module deployments
Sometimes some resources should be created before module deployment with helm. Most common things are **namespaces** and **CRDs**, which are not very well handled with current helm deployemnts. Yes, helm can deploy CRDs from /crds folder utomatically, but if you have *kubernetes* hooks which reference those CRDs, they will not work. 

For that platform have common ```common::ensure_resources()``` function which will deploy all resources from *resources* folder on hook execution.
You can check the hook example here [modules/001-cert-platform/hooks/ensureResources.sh](modules/110-cert-platform/hooks/ensureResources.sh)

### Dependencies subcharts
**addon-operator** has one significant limitation - it is hard to use external helm charts as dependencies (see https://github.com/flant/addon-operator/issues/153). Main issue is that values files in **addon-operator**  has special structure which is not compatible with subcharts values convention in Helm.

In order to overcome this it ispossible to introduce empty subchart named as module name in camelCase  as first dependency of the module. All external dependencies should be placed as subcharts of that empty subchart.
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
### Download helm dependencies

If you are using dependecies subcharts in a module, then usually you want to have them outside of this repo. So they need to be downloded before helm deployment of the module.

For that platform have common ```helm::run_helm_dependency_update_hook()``` function which will download all dependencies fron */charts* folder, e.g. see  [modules/001-cert-platform/hooks/helm-update-dependencies.sh](modules/110-cert-platform/hooks/helm-update-dependencies.sh)