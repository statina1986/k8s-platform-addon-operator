# postgres-platform module
This module is responsible for deployment of [Zalando Postgres Operator](https://github.com/zalando/postgres-operator) in the cluster.

Depends on modules:
- [platform-core](/modules/101-platform-core/README.md) from which *platform* Service Account is used

Provides:
- Zalando Postgres Operator deployment
- Configuration of postgres cluster CRDs (kind: postgresql)

## Qvantel Spilo Images
Zalando Postgres Operator allows to override spilo docker image in postgresql cluster definition.
In Qvantel we have custom-built spilo base images (see https://stash.qvantel.net/projects/DC/repos/spilo). Those images are built with Timescale community license enabled and Instana instrumentation disabled. Those should be used whenever Timescale DB required.

## Known Limitations
- Zalando Postgres Operator doesn't play well with Kyverno artifactory image replacement policy (see [kyverno-platform](../modules/010-010-kyverno-platform/README.md)). When image in the pod is different from image in the Stateful Set, postgres operator will restart cluster pods on every reconciliation (every 30 min by default). In order to avoid we need to always set `dockerImage` to some Artifactory-based image. 