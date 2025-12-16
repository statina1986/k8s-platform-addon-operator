
# ECK-operator upgrades

ECK-operator was tested that the upgrade from 1.9.1 to 2.2.0 can be done by normally running the addon-operator, with the new charts and configurations. When doing a upgrade the PVCs are going to be lost if the following configuration is not defined in the target elasticsearch configuration:
- volumeClaimDeletePolicy: DeleteOnScaledownOnly
This configuration is also definable in the values by the name of volumePolicy.

When running a upgrade the downtime for elasticsearch will be around 5mins and if this is not acceptable you can temporaly remove some of the elasticsearch nodes from the ECK-operators management. The guide below will walk you trough the process:
- [k8s-upgrading-eck](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-upgrading-eck.html) This was not tested, because there should not be need for it.

# Filebeat connections to Vector

Filebeat can be utilized on VM nodes, like Tibco nodes, to transmit traffic to the k8s cluster. In order to send the traffic to Vector, it's essential to change the logstash address to vector-aggregator, which sends the traffic to Elasticsearch and Loki. Here's an example:

    output.logstash:
      hosts:
      	- vector-platform-aggregator.service.consul:9000

# Dependencies:

No dependencies.