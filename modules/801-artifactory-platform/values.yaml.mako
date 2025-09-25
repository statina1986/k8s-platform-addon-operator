artifactoryPlatform:
  artifactory-oss:
    # -- Enable deployment of OSS Artifactory.
    enabled: false
    artifactory:
      # -- 'fullnameOverride' fully overrides the deployment name.
      fullnameOverride: artifactory-oss
      # -- Router microservice, discovers other artifactory microservices. See https://jfrog.com/help/r/artifactory-s-microservices-explained/router
      router:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          repository: jfrog/router
          % endif
      initContainers:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % else:
          registry: platform.artifactory.qvantel.net
          % endif
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.3_202509080945_master_90384dcc
      artifactory:
        # -- 'name' must be same with the 'fullnameOverride'.
        name: "artifactory-oss"
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % endif
          repository: jfrog/artifactory-oss
        # -- Defines admin secrets. 
        admin:
          # -- Kube secret name 
          secret: artifactory-oss-admin-secret
          # -- Key identifier set in the kube 'secret'
          dataKey: bootstrap.creds
      # -- Enable separate nginx container.
      nginx:
        enabled: false
      # -- Enable PostgreSQL dependency sub-chart. Not required in qvantel platform.
      postgresql:
        enabled: false
      # -- Main DB configuration
      database:
        type: postgresql
        driver: org.postgresql.Driver
        # -- Define existing postgredb cluster. CNPG module default cluster name used.
        url: "jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-oss"
        # -- Define DB secret names that are created by the deployment.
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
    # -- Enable deployment of JCR Artifactory.
    enabled: false
    artifactory:
      # -- 'fullnameOverride' fully overrides the deployment name.
      fullnameOverride: artifactory-jcr
      # -- Router microservice, discovers other artifactory microservices. See https://jfrog.com/help/r/artifactory-s-microservices-explained/router
      router:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}        
          repository: jfrog/router
          % endif
      initContainers:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % else:
          registry: platform.artifactory.qvantel.net
          % endif
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.3_202509080945_master_90384dcc
      artifactory:
        # -- 'name' must be same with the 'fullnameOverride'.
        name: "artifactory-jcr"
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          repository: jfrog/artifactory-jcr
          % endif
        # -- Defines admin secrets. 
        admin:
          secret: artifactory-jcr-admin-secret
          dataKey: bootstrap.creds
      # -- Enable separate nginx container.
      nginx:
        enabled: false
      # -- Enable PostgreSQL dependency sub-chart. Not required in qvantel platform.
      postgresql:
        enabled: false
      # -- Kube secret name 
      database:
        type: postgresql
        driver: org.postgresql.Driver
        # -- Define existing postgredb cluster. CNPG module default cluster name used.
        url: "jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-jcr"
        # -- Define DB secret names that are created by the deployment.
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
  # -- Qvantel CNPG module database override. 
  databaseOSS:
    enabled: true
    # -- PostgreSQL cluster name override.
    name: qvt-postgredb
  databaseJCR:
    enabled: true
    # -- PostgreSQL cluster name override.
    name: qvt-postgredb
