apiVersion: v2
name: rancherPlatform
version: 0.0.1
dependencies:
  - name: rancher
    version: ${values['rancherPlatform']['rancherHelmVersion'] or '2.9.2'}
    repository: https://releases.rancher.com/server-charts/latest