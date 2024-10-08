apiVersion: v2
name: kafkaPlatform
version: 0.0.1
dependencies:
  - name: strimzi-kafka-operator    
    version: ${values['kafkaPlatform']['strimziHelmVersion'] or '0.43.0'}
    repository: https://strimzi.io/charts/
  - name: kafka-ui
    version: 1.4.2
    repository: https://kafbat.github.io/helm-charts/
