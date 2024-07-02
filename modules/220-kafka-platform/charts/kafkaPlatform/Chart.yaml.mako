apiVersion: v2
name: kafkaPlatform
version: 0.0.1
dependencies:
#  - name: strimzi-kafka-operator
#    version: 0.27.1
#    repository: https://strimzi.io/charts/
  - name: strimzi-kafka-operator    
    version: ${values['kafkaPlatform']['strimziHelmVersion'] or '0.37.0'}
    repository: https://strimzi.io/charts/
