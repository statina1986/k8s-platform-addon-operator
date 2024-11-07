# artifactory-platform

This module provides two versions of [Artifactory](https://jfrog.com/artifactory/) deployment on kubernetes. [OSS](https://artifacthub.io/packages/helm/jfrog/artifactory-oss) and [JCR](https://artifacthub.io/packages/helm/jfrog/artifactory-jcr).

Depends on modules:
- [cnpg-postgres-platform](/modules/241-cnpg-postgres-platform/README.md) which is by default is used as main database for both versions.

Provides:
- OSS artifactory
- JCR artifactory
- Database configurability (cnpg recommended)

Both versions available at:
- artifactory-oss.platform.svc
- artifactory-jcr.platform.svc

### Minimal configuration
* This is minimal required configuration for deploying either both or another of these versions: 
  ```
  artifactoryPlatformEnabled: "true"
  artifactoryPlatform:
    artifactory-oss:
      enabled: true
    artifactory-jcr:
      enabled: true
  ```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| artifactoryPlatform.artifactory-jcr.artifactory.artifactory.admin | object | `{"dataKey":"bootstrap.creds","secret":"artifactory-jcr-admin-secret"}` | Defines admin secrets.  |
| artifactoryPlatform.artifactory-jcr.artifactory.artifactory.image.registry | string | `"platform.artifactory.qvantel.net/k8s-platform-1-2-0"` |  |
| artifactoryPlatform.artifactory-jcr.artifactory.artifactory.image.repository | string | `"jfrog/artifactory-jcr"` |  |
| artifactoryPlatform.artifactory-jcr.artifactory.artifactory.name | string | `"artifactory-jcr"` | 'name' must be same with the 'fullnameOverride'. |
| artifactoryPlatform.artifactory-jcr.artifactory.database | object | `{"driver":"org.postgresql.Driver","secrets":{"password":{"key":"password","name":"qvt-postgredb-artifactory-jcr"},"url":{"key":"db-url","name":"qvt-postgredb-artifactory-jcr"},"user":{"key":"username","name":"qvt-postgredb-artifactory-jcr"}},"type":"postgresql","url":"jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-jcr"}` | Kube secret name  |
| artifactoryPlatform.artifactory-jcr.artifactory.database.secrets | object | `{"password":{"key":"password","name":"qvt-postgredb-artifactory-jcr"},"url":{"key":"db-url","name":"qvt-postgredb-artifactory-jcr"},"user":{"key":"username","name":"qvt-postgredb-artifactory-jcr"}}` | Define DB secret names that are created by the deployment. |
| artifactoryPlatform.artifactory-jcr.artifactory.database.url | string | `"jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-jcr"` | Define existing postgredb cluster. CNPG module default cluster name used. |
| artifactoryPlatform.artifactory-jcr.artifactory.fullnameOverride | string | `"artifactory-jcr"` | 'fullnameOverride' fully overrides the deployment name. |
| artifactoryPlatform.artifactory-jcr.artifactory.nginx | object | `{"enabled":false}` | Enable separate nginx container. |
| artifactoryPlatform.artifactory-jcr.artifactory.postgresql | object | `{"enabled":false}` | Enable PostgreSQL dependency sub-chart. Not required in qvantel platform. |
| artifactoryPlatform.artifactory-jcr.enabled | bool | `false` | Enable deployment of JCR Artifactory. |
| artifactoryPlatform.artifactory-jcr.initContainers.image.registry | string | `"platform.artifactory.qvantel.net/k8s-platform-1-2-0"` |  |
| artifactoryPlatform.artifactory-jcr.initContainers.image.repository | string | `"ubi9/ubi-minimal"` |  |
| artifactoryPlatform.artifactory-jcr.initContainers.image.tag | string | `"9.4-1194"` |  |
| artifactoryPlatform.artifactory-jcr.router | object | `{"image":{"registry":"platform.artifactory.qvantel.net/k8s-platform-1-2-0","repository":"jfrog/router","tag":"7.118.0"}}` | Router microservice, discovers other artifactory microservices. See https://jfrog.com/help/r/artifactory-s-microservices-explained/router |
| artifactoryPlatform.artifactory-oss.artifactory.artifactory.admin | object | `{"dataKey":"bootstrap.creds","secret":"artifactory-oss-admin-secret"}` | Defines admin secrets.  |
| artifactoryPlatform.artifactory-oss.artifactory.artifactory.admin.dataKey | string | `"bootstrap.creds"` | Key identifier set in the kube 'secret' |
| artifactoryPlatform.artifactory-oss.artifactory.artifactory.admin.secret | string | `"artifactory-oss-admin-secret"` | Kube secret name  |
| artifactoryPlatform.artifactory-oss.artifactory.artifactory.image.registry | string | `"platform.artifactory.qvantel.net/k8s-platform-1-2-0"` |  |
| artifactoryPlatform.artifactory-oss.artifactory.artifactory.image.repository | string | `"jfrog/artifactory-oss"` |  |
| artifactoryPlatform.artifactory-oss.artifactory.artifactory.name | string | `"artifactory-oss"` | 'name' must be same with the 'fullnameOverride'. |
| artifactoryPlatform.artifactory-oss.artifactory.database | object | `{"driver":"org.postgresql.Driver","secrets":{"password":{"key":"password","name":"qvt-postgredb-artifactory-oss"},"url":{"key":"db-url","name":"qvt-postgredb-artifactory-oss"},"user":{"key":"username","name":"qvt-postgredb-artifactory-oss"}},"type":"postgresql","url":"jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-oss"}` | Main DB configuration |
| artifactoryPlatform.artifactory-oss.artifactory.database.secrets | object | `{"password":{"key":"password","name":"qvt-postgredb-artifactory-oss"},"url":{"key":"db-url","name":"qvt-postgredb-artifactory-oss"},"user":{"key":"username","name":"qvt-postgredb-artifactory-oss"}}` | Define DB secret names that are created by the deployment. |
| artifactoryPlatform.artifactory-oss.artifactory.database.url | string | `"jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-oss"` | Define existing postgredb cluster. CNPG module default cluster name used. |
| artifactoryPlatform.artifactory-oss.artifactory.fullnameOverride | string | `"artifactory-oss"` | 'fullnameOverride' fully overrides the deployment name. |
| artifactoryPlatform.artifactory-oss.artifactory.nginx | object | `{"enabled":false}` | Enable separate nginx container. |
| artifactoryPlatform.artifactory-oss.artifactory.postgresql | object | `{"enabled":false}` | Enable PostgreSQL dependency sub-chart. Not required in qvantel platform. |
| artifactoryPlatform.artifactory-oss.enabled | bool | `false` | Enable deployment of OSS Artifactory. |
| artifactoryPlatform.artifactory-oss.initContainers.image.registry | string | `"platform.artifactory.qvantel.net/k8s-platform-1-2-0"` |  |
| artifactoryPlatform.artifactory-oss.initContainers.image.repository | string | `"ubi9/ubi-minimal"` |  |
| artifactoryPlatform.artifactory-oss.initContainers.image.tag | string | `"9.4-1194"` |  |
| artifactoryPlatform.artifactory-oss.router | object | `{"image":{"registry":"platform.artifactory.qvantel.net/k8s-platform-1-2-0","repository":"jfrog/router","tag":"7.118.0"}}` | Router microservice, discovers other artifactory microservices. See https://jfrog.com/help/r/artifactory-s-microservices-explained/router |
| artifactoryPlatform.databaseJCR.enabled | bool | `true` |  |
| artifactoryPlatform.databaseJCR.name | string | `"qvt-postgredb"` | PostgreSQL cluster name override. |
| artifactoryPlatform.databaseOSS | object | `{"enabled":true,"name":"qvt-postgredb"}` | Qvantel CNPG module database override.  |
| artifactoryPlatform.databaseOSS.name | string | `"qvt-postgredb"` | PostgreSQL cluster name override. |