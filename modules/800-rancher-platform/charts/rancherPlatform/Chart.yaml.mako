apiVersion: v2
name: rancherPlatform
version: 0.0.1
dependencies:
  - name: rancher
    version: ${values['rancherPlatform']['rancherHelmVersion'] or '2.9.2'}
    repository: https://artifactory.qvantel.net:443/artifactory/all-docker/rancher/