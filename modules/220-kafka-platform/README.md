

# kafka-platform

<!-- BRIEF -->
This module is responsible for deployment of [Strimzi Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator) in the cluster.

Depends on modules:
- no dependencies

Provides:
- Strimzi Kafka Operator deployment
- Configuration of kafka cluster CRDs (kind: Kafka)
- kafbat UI deployment

## Running in development environments
Current default settings assume High Availability setup with 3 Availability Zones. So it will not run in local development environment with less than 3 Nodes. For local development you might want to change the configuration of the cluster removing affinities and topology spread constraints.

## Values

<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;" id="kafkaPlatform--clusters">kafkaPlatform.clusters</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>kafka-cluster:
    annotations:
        strimzi.io/kraft: enabled
        strimzi.io/node-pools: enabled
    enabled: true
    nodePools:
        controller:
            enabled: true
            spec:
                replicas: 3
                resources:
                    limits:
                        cpu: "1"
                        memory: 2Gi
                    requests:
                        cpu: "0.1"
                        memory: 1Gi
                roles:
                    - controller
                storage:
                    deleteClaim: false
                    size: 2Gi
                    type: persistent-claim
                template:
                    pod:
                        affinity:
                            podAntiAffinity:
                                requiredDuringSchedulingIgnoredDuringExecution:
                                    - labelSelector:
                                        matchExpressions:
                                            - key: strimzi.io/controller-role
                                              operator: In
                                              values:
                                                - "true"
                                            - key: strimzi.io/cluster
                                              operator: In
                                              values:
                                                - kafka-cluster
                                      topologyKey: kubernetes.io/hostname
                        tolerations:
                            - effect: NoSchedule
                              key: dedicated-nodes
                              operator: Equal
                              value: platform-masters
        kafka:
            enabled: true
            spec:
                replicas: 3
                resources:
                    limits:
                        cpu: "1"
                        memory: 4Gi
                    requests:
                        cpu: "0.5"
                        memory: 2Gi
                roles:
                    - broker
                storage:
                    deleteClaim: false
                    size: 10Gi
                    type: persistent-claim
                template:
                    pod:
                        affinity:
                            podAntiAffinity:
                                requiredDuringSchedulingIgnoredDuringExecution:
                                    - labelSelector:
                                        matchExpressions:
                                            - key: strimzi.io/broker-role
                                              operator: In
                                              values:
                                                - "true"
                                            - key: strimzi.io/cluster
                                              operator: In
                                              values:
                                                - kafka-cluster
                                      topologyKey: kubernetes.io/hostname
                        tolerations:
                            - effect: NoSchedule
                              key: dedicated-nodes
                              operator: Equal
                              value: platform-masters
    spec:
        entityOperator:
            template:
                pod:
                    tolerations:
                        - effect: NoSchedule
                          key: dedicated-nodes
                          operator: Equal
                          value: platform-masters
            topicOperator: {}
            userOperator: {}
        kafka:
            config:
                auto.create.topics.enable: "true"
                compression.type: lz4
                default.replication.factor: 3
                delete.topic.enable: true
                group.initial.rebalance.delay.ms: 3000
                log.retention.hours: 168
                min.insync.replicas: 2
                num.partitions: 6
                offsets.topic.replication.factor: 3
                transaction.state.log.min.isr: 2
                transaction.state.log.replication.factor: 3
            listeners:
                - name: plain
                  port: 9092
                  tls: false
                  type: internal
                - name: tls
                  port: 9093
                  tls: true
                  type: internal
            livenessProbe:
                initialDelaySeconds: 15
                timeoutSeconds: 5
            metricsConfig:
                type: jmxPrometheusExporter
                valueFrom:
                    configMapKeyRef:
                        key: kafka-metrics-config.yml
                        name: kafka-metrics
            readinessProbe:
                initialDelaySeconds: 15
                timeoutSeconds: 5
            version: 3.9.1
        kafkaExporter:
            groupRegex: .*
            template:
                pod:
                    tolerations:
                        - effect: NoSchedule
                          key: dedicated-nodes
                          operator: Equal
                          value: platform-masters
            topicRegex: .*</code></pre>
</td>
			<td><div>

List of clusters to provision. Spec for each cluster is configured according to "kafka.strimzi.io/v1beta2" resource. ( https://strimzi.io/docs/operators/0.43.0/configuring.html#type-KafkaClusterSpec-reference )

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kafkaPlatform--clusters--kafka-cluster--spec--kafka--listeners">kafkaPlatform.clusters.kafka-cluster.spec.kafka.listeners</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- name: plain
  port: 9092
  tls: false
  type: internal
- name: tls
  port: 9093
  tls: true
  type: internal</code></pre>
</td>
			<td><div>

Kafka listener configuration ( https://strimzi.io/docs/operators/0.43.0/configuring.html#type-GenericKafkaListener-schema-reference )

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kafkaPlatform--clusters--kafka-cluster--spec--kafkaExporter">kafkaPlatform.clusters.kafka-cluster.spec.kafkaExporter</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>groupRegex: .*
template:
    pod:
        tolerations:
            - effect: NoSchedule
              key: dedicated-nodes
              operator: Equal
              value: platform-masters
topicRegex: .*</code></pre>
</td>
			<td><div>

KafkaExporter configuration ( https://strimzi.io/docs/operators/0.43.0/configuring.html#type-KafkaExporterSpec-reference )

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kafkaPlatform--kafka-ui--authConfig">kafkaPlatform.kafka-ui.authConfig</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>oauth2:
    client:
        keycloak:
            authorization-grant-type: authorization_code
            client-name: keycloak
            clientId: kafbat
            clientSecret: ${KAFKA_UI_CLIENT_SECRET}
            custom-params:
                roles-field: roles
                type: oauth
            issuer-uri: https://auth-some-env.qvantel.solutions/auth/realms/qvantel
            jwk-set-uri: http://qvaa-proxy-80/auth/realms/qvantel/protocol/openid-connect/certs
            provider: keycloak
            scope: openid
            user-name-attribute: preferred_username
type: OAUTH2</code></pre>
</td>
			<td><div>

Kafbat UI authconfig ( https://ui.docs.kafbat.io/configuration/authentication )

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kafkaPlatform--kafka-ui--authConfig--oauth2">kafkaPlatform.kafka-ui.authConfig.oauth2</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>client:
    keycloak:
        authorization-grant-type: authorization_code
        client-name: keycloak
        clientId: kafbat
        clientSecret: ${KAFKA_UI_CLIENT_SECRET}
        custom-params:
            roles-field: roles
            type: oauth
        issuer-uri: https://auth-some-env.qvantel.solutions/auth/realms/qvantel
        jwk-set-uri: http://qvaa-proxy-80/auth/realms/qvantel/protocol/openid-connect/certs
        provider: keycloak
        scope: openid
        user-name-attribute: preferred_username</code></pre>
</td>
			<td><div>

By default OAuth2 is configured ( https://ui.docs.kafbat.io/configuration/authentication/oauth2 )

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kafkaPlatform--kafka-ui--rolesConfig">kafkaPlatform.kafka-ui.rolesConfig</td>
			<td>tpl</td>
			<td>
<pre style="max-width:500px; overflow-x:auto; white-space: pre;" lang="tpl"><code>kafkaPlatform.kafka-ui.rolesConfig: |
  roles:
    {{- range keys .Values.kafkaPlatform.clusters }}
    {{- $current := get $.Values.kafkaPlatform.clusters . }}
    {{- if $current.enabled }}
    {{- $cluster_name := . }}
    - name: "kafka-admins-{{ $cluster_name }}"
      clusters:
        - {{ $cluster_name }}
      subjects:
        - provider: oauth
          type: role
          value: "kafka-admins"
      permissions:
        - resource: applicationconfig
          actions: all
        - resource: clusterconfig
          actions: all
        - resource: topic
          value: ".*"
          actions: all
        - resource: consumer
          value: ".*"
          actions: all
        - resource: schema
          value: ".*"
          actions: all
        - resource: connect
          value: ".*"
          actions: all
        - resource: ksql
          actions: all
        - resource: acl
          actions: [ view ]
    - name: "kafka-readonly-{{ $cluster_name }}"
      clusters:
        - {{ $cluster_name }}
      subjects:
        - provider: oauth
          type: role
          value: "kafka-readonly"
      permissions:
        - resource: clusterconfig
          actions: [ "view" ]
        - resource: topic
          value: ".*"
          actions:
            - VIEW
            - MESSAGES_READ
        - resource: consumer
          value: ".*"
          actions: [ view ]
        - resource: schema
          value: ".*"
          actions: [ view ]
        - resource: connect
          value: ".*"
          actions: [ view ]
        - resource: acl
          actions: [ view ]         
    {{- end }}
    {{- end }}
    {{ tpl  (index .Values.kafkaPlatform "kafka-ui" "additionalRoles") . | nindent 8 }}
 
</code></pre>
</td>
			<td><div>

Role based access control for kafbat ui ( https://ui.docs.kafbat.io/configuration/rbac-role-based-access-control ) - rolesConfig becomes rbac with [our templating](./templates/kafka-ui-cm.yaml).

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="kafkaPlatform--strimzi-kafka-operator">kafkaPlatform.strimzi-kafka-operator</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>defaultImageRegistry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
resources:
    limits:
        cpu: "1"
        memory: 1Gi
    requests:
        cpu: 200m
        memory: 384Mi
serviceAccount: platform
serviceAccountCreate: false
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

configuration of Strimzi Operator. Values specification: https://github.com/strimzi/strimzi-kafka-operator/blob/main/helm-charts/helm3/strimzi-kafka-operator/values.yaml

</div>
</td>
		</tr>
	</tbody>
</table>

