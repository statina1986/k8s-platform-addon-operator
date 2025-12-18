
# K8S Platform Services

This repo contains implementation of **K8S Platform Services** based on the [addon-operator](https://github.com/flant/addon-operator)

>
> Please check [addon-operator](https://github.com/flant/addon-operator) documentation first
> 

## Available modules
<!-- TABLEMARKER -->
| module | brief description |
|:-|:-|
| [001-platform-core](./modules/001-platform-core) | Provides common core features of the platform. **Should be always enabled**. | 
| [010-kyverno-platform](./modules/010-kyverno-platform) | This module provides https://kyverno.io/ policy engine platform service. | 
| [050-aws-platform](./modules/050-aws-platform) | This module configures needed plugins and services to run Qvantel K8S Platfrom on AWS EKS clusters and within AWS Cloud | 
| [101-cert-platform](./modules/101-cert-platform) | This module is responsible for deployment of [cert-manager](https://cert-manager.io/docs/) in the cluster and configuration of required platform certificates | 
| [105-istio-platform](./modules/105-istio-platform) | This module is responsible for deployment of [Istio](https://github.com/istio/istio) control plane to the cluster | 
| [110-monitoring-platform](./modules/110-monitoring-platform) | This module configures Qvantel monitoring platform components to provide visibility to all that is happening inside the K8s cluster. | 
| [111-metrics-platform](./modules/111-metrics-platform) | This module is responsible for deployment of [metrics-server](https://github.com/kubernetes-sigs/metrics-server/) in the cluster | 
| [120-external-dns](./modules/120-external-dns) | This module is responsible for deployment of [external-dns](https://github.com/kubernetes-sigs/external-dns) in the cluster | 
| [130-consul-platform](./modules/130-consul-platform) | This module is responsible for deployment of [Consul](https://www.consul.io/) in the cluster | 
| [140-vault-platform](./modules/140-vault-platform) | This module is responsible for deployment of [vault](https://www.vaultproject.io/) in the cluster | 
| [145-minio-platform](./modules/145-minio-platform) | `minio-platform` module is responsible for deployment of [MinIO](https://min.io/) in the cluster. Most common use case for this is when off site S3 backend such as AWS S3 is not available. | 
| [151-istio-ingress](./modules/151-istio-ingress) | This module is responsible for deployment of [Istio](https://github.com/istio/istio) Ingress Gateway solution in the cluster. | 
| [159-opensearch-platform](./modules/159-opensearch-platform) | Basic [OpenSearch](https://opensearch.org/) module. | 
| [160-elasticsearch-platform](./modules/160-elasticsearch-platform) | Deploys Elasticsearch and Kibana using ECK Operator | 
| [161-logsearch-platform](./modules/161-logsearch-platform) | This module is responsible for deployment of Bitnami ElasticSearch ( LogSearch ). | 
| [162-smartsearch-platform](./modules/162-smartsearch-platform) | This module is responsible for deployment of Bitnami ElasticSearch ( SmartSearch ). | 
| [163-loki-platform](./modules/163-loki-platform) | This module is responsible for deploying [Grafana Loki](https://grafana.com/oss/loki/). | 
| [164-vector-platform](./modules/164-vector-platform) | This module is responsible for deployment of [Vector](https://vector.dev/) and [Fluent Bit](https://fluentbit.io/). | 
| [170-velero-platform](./modules/170-velero-platform) | This module is responsible for deployment of [Velero](https://cert-manager.io/docs/) | 
| [211-kasope-platform](./modules/211-kasope-platform) | `kasope-platform` module is responsible for deployment of [K8ssandra Operator](https://docs.k8ssandra.io/components/k8ssandra-operator/) in the cluster. | 
| [220-kafka-platform](./modules/220-kafka-platform) | This module is responsible for deployment of [Strimzi Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator) in the cluster. | 
| [230-progress-platform](./modules/230-progress-platform) | This module is now responsible to bring auxilary needed stuff to support external Progress DB. | 
| [241-cnpg-postgres-platform](./modules/241-cnpg-postgres-platform) | This module is responsible for deployment of [CNPG Operator](https://cloudnative-pg.io/documentation/current/). | 
| [251-mariadb-operator-platform](./modules/251-mariadb-operator-platform) | This module is responsible for deployment of MariaDB Operator (https://github.com/mariadb-operator/mariadb-operator) | 
| [260-redis-platform](./modules/260-redis-platform) | This module is responsible for deployment of Redis (https://github.com/redis/redis) | 
| [270-rabbitmq-platform](./modules/270-rabbitmq-platform) | This module deploys [Bitnami's Rabbitmq](https://artifacthub.io/packages/helm/bitnami/rabbitmq/15.2.4) chart, providing RabbitMQ version 4.0.5. | 
| [280-mongodb-platform](./modules/280-mongodb-platform) | This module deploys [Bitnami's MongoDB](https://artifacthub.io/packages/helm/bitnami/mongodb/15.6.12) chart. | 
| [290-percona-pmm-platform](./modules/290-percona-pmm-platform) | open-source database monitoring, management, and observability platform for MySQL, PostgreSQL, and MongoDB | 
| [315-pomerium-platform](./modules/315-pomerium-platform) | This module is responsible for deployment of [Pomerium](https://www.pomerium.com/) | 
| [320-qvantel-glue](./modules/320-qvantel-glue) | `qvantel-glue` module provides abstractions and automations to support Qvantel workloads deployments and operations. | 
| [370-instana-platform](./modules/370-instana-platform) | This module is responsible for [instana](https://www.instana.com) deployment | 
| [410-sftpgo-platform](./modules/410-sftpgo-platform) | This module offers [Drakkan's SFTPGo](https://github.com/drakkan/sftpgo), providing SFTPGo version 2.7.0 by default. | 
| [500-apisix-platform](./modules/500-apisix-platform) | This module is responsible for [apisix](https://apisix.apache.org/) deployment | 
| [600-ksix-platform](./modules/600-ksix-platform) | This module is responsible for [K6](https://github.com/grafana/k6) deployment | 
| [800-rancher-platform](./modules/800-rancher-platform) | This module is created for Rancher installations | 
| [801-artifactory-platform](./modules/801-artifactory-platform) | This module provides two versions of [Artifactory](https://jfrog.com/artifactory/) deployment on kubernetes. [OSS](https://artifacthub.io/packages/helm/jfrog/artifactory-oss) and [JCR](https://artifacthub.io/packages/helm/jfrog/artifactory-jcr). | 
| [802-metallb-platform](./modules/802-metallb-platform) | This module is responsible for deployment of [MetalLB](https://github.com/metallb/metallb) in the cluster and the helm chart was community made, which can be found in [Github](https://github.com/metallb/metallb/tree/main/charts/metallb). | 
| [810-keycloak-platform](./modules/810-keycloak-platform) | `keycloak-platform` module is responsible for deployment of [Keycloak](https://www.keycloak.org/) in the cluster. | 
| [900-shutdown-operator](./modules/900-shutdown-operator) | This module deploys the shutdown-addon-operator, that is used to manage the cluster scaledown / up separate from the main addon-operator. | 
<!-- TABLEMARKER -->

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
