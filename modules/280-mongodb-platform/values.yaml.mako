mongodbPlatform:
  mongodb:
    global:
      security:
        allowInsecureImages: true
    # -- Deploying as replicaset as opposed to standalone,
    # resulting in an arbiter and two instances, primary
    # and secondary, which may swap.
    architecture: replicaset
    image:
      # Uses custom multiarch image built from https://hub.docker.com/r/dlavrenuek/bitnami-mongodb-arm, see: https://qvantel.atlassian.net/browse/QOPS-54054?focusedCommentId=2569996
      repository: platform/bitnami-mongodb
      tag: "7.0.28"
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      % else:
      registry: platform.artifactory.qvantel.net
      % endif
    tls:
      image:
        repository: bitnamilegacy/nginx
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: docker.io
        % endif
        tag: 1.27.0-debian-12-r2
    externalAccess:
      autoDiscovery:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % else:
          registry: platform.artifactory.qvantel.net
          % endif
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.3_202509080945_master_90384dcc
      dnsCheck:
        image:
          % if 'containerRegistryBase' in values['global']:
          registry: ${values['global']['containerRegistryBase']}
          % else:
          registry: platform.artifactory.qvantel.net
          % endif
          repository: platform/platform-k8s-tools-minimal
          tag: 1.3.3_202509080945_master_90384dcc
    volumePermissions:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: platform.artifactory.qvantel.net
        % endif
        repository: platform/platform-k8s-tools-minimal
        tag: 1.3.3_202509080945_master_90384dcc
    metrics:
      enabled: false
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        % else:
        registry: docker.io
        % endif
        repository: bitnamilegacy/mongodb-exporter
        tag: 0.40.0-debian-12-r30
      