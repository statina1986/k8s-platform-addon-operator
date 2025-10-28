apiVersion: v2
name: kafkaPlatform
version: 0.0.1
dependencies:
  - name: strimzi-kafka-operator    
    version: ${values['kafkaPlatform']['strimziHelmVersion'] or '0.45.1'}
    repository: https://strimzi.io/charts/
  - name: kafka-ui
    version: 1.5.1
    repository: https://kafbat.github.io/helm-charts/
