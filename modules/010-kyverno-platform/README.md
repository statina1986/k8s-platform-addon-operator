This module provides https://kyverno.io/ policy engine platform service. It is deployed very first in pipeline in order to be able to provide Qvantel Artifactory images policy enforcement, so all pod's images will be replaced with Qvantel Artifactory repository.

Depends on modules:
- no dependencies

Provides:
- Kyverno Helm Deployment, see https://kyverno.io/docs/introduction/

Policies Included:
- 


This module is deployed to namespace `kyverno`, not `platform`. This is needed to allow `kyverno` namespace exclusion, see https://kyverno.io/docs/installation/#security-vs-operability
As side effect, this module can't be automatically deleted by addon-operator, so manual "helm unistall" will be needed in order to uninstall it.



Customizations:
- 'policyReportsCleanup' image is replaced from 'bitnami/kubectl' to 'platform/platform-k8s-tools-minimal:1.2.0'
- 'webhooksCleanup' image is replaced from 'bitnami/kubectl' to 'platform/platform-k8s-tools-minimal:1.2.0'
- 'test' image is replaced from 'busybox' to 'platform/platform-k8s-tools-minimal:1.2.0'
