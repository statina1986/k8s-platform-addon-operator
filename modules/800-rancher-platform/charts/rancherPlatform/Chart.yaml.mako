apiVersion: v2
name: rancherPlatform
version: 0.0.1
dependencies:
  - name: rancher
    version: ${values['rancherPlatform']['rancherHelmVersion'] or '2.8.1'}
    repository: https://artifactory.qvantel.net:443/artifactory/all-docker/rancher/