artifactoryPlatform:
  artifactory-oss: 
    enabled: false
    router:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: jfrog/router
        tag: 7.118.0
    initContainers:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: ubi9/ubi-minimal
        tag: 9.4-1194
    artifactory:
      fullnameOverride: artifactory-oss
      artifactory:
        image:
          registry: ${values['global']['containerRegistryBase']}
          repository: jfrog/artifactory-oss
        admin:
          secret: artifactory-oss-admin-secret
          dataKey: bootstrap.creds
      nginx:
        enabled: false
      postgresql:
        enabled: false
      database:
        type: postgresql
        driver: org.postgresql.Driver
        url: "jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-oss"
        secrets:
          user:
            name: "qvt-postgredb-artifactory-oss"
            key: "username"
          password:
            name: "qvt-postgredb-artifactory-oss"
            key: "password"
          url:
            name: "qvt-postgredb-artifactory-oss"
            key: "db-url"
  artifactory-jcr:
    enabled: false
    router:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: jfrog/router
        tag: 7.118.0
    initContainers:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: ubi9/ubi-minimal
        tag: 9.4-1194
    artifactory:
      fullnameOverride: artifactory-jcr
      artifactory:
        image:
          registry: ${values['global']['containerRegistryBase']}
          repository: jfrog/artifactory-jcr
        admin:
          secret: artifactory-jcr-admin-secret
          dataKey: bootstrap.creds
      nginx:
        enabled: false
      postgresql:
        enabled: false
      
      database:
        type: postgresql
        driver: org.postgresql.Driver
        url: "jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-jcr"
        secrets:
          user:
            name: "qvt-postgredb-artifactory-jcr"
            key: "username"
          password:
            name: "qvt-postgredb-artifactory-jcr"
            key: "password"
          url:
            name: "qvt-postgredb-artifactory-jcr"
            key: "db-url"
  databaseOSS:
    enabled: true
    name: qvt-postgredb
  databaseJCR:
    enabled: true
    name: qvt-postgredb
