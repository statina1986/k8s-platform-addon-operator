

# vector-platform

This module is responsible for deployment of [Vector](https://vector.dev/) and [Fluent Bit](https://fluentbit.io/).

Current pipeline configuration:
* Vector agents collect logs from k8s nodes and send them to Vector Aggregator
* Fluent bit collects Kubernetes events and sends them to Vector Aggregator
* Vector Aggregator performs all the log transformations and filtering
    * Qvantel apps tranformation expects logs in [Generic Log Format](https://qvantel.atlassian.net/wiki/spaces/PDG/pages/1358727788/Generic+Log+Format)
* Vector Aggregator sends logs to Loki and optionally to ElasticSearch

## Deployment Models

Vector Agents are a DaemonSet and always transfer the logs to Aggregator so there is no effect on its functionality, when deploying, with different configurationProfiles.
Vector Aggregator on the other hand is a StatefulSet and manages where we send the logs so when deploying with different configurationProfiles, changes are made based on the environment.

globalConfig.configurationProfile values effects explained below:
* dev
    * Endpoint points towards the loki-platform
* test
    * Endpoint points towards the loki-write
* perf, prod
    * Endpoint points towards the loki-write
    * Replicas 3
    * nodeSelector set to platform-masters

Dependencies:
- A log sink
    - with our default configuration, that is [Loki](../163-loki-platform/).
- globalConfig.appsNamespace needs to be configured

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
			<td style="width: 300px;" id="vectorPlatform--agent">vectorPlatform.agent</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>customConfig:
    api:
        address: 0.0.0.0:8686
        enabled: true
        playground: false
    data_dir: /vector-data-dir
    sinks:
        prometheus:
            address: 0.0.0.0:9598
            inputs:
                - vector_metrics_transform
            type: prometheus_exporter
        vector:
            address: vector-platform-aggregator.platform.svc:6000
            inputs:
                - kubernetes_logs_transform
                - vector_logs_transform
            type: vector
    sources:
        kubernetes:
            type: kubernetes_logs
        vector_logs:
            type: internal_logs
        vector_metrics:
            type: internal_metrics
    transforms:
        kubernetes_logs_transform:
            inputs:
                - kubernetes
            source: ".log_source = \"kubernetes_logs\"      \nif exists(.kubernetes.namespace_labels) {\n  del(.kubernetes.namespace_labels)\n}\n"
            type: remap
        vector_logs_transform:
            inputs:
                - vector_logs
            source: |
                .log_source = "vector_logs"
            type: remap
        vector_metrics_transform:
            inputs:
                - vector_metrics
            source: |
                del(.tags.file)
            type: remap
enabled: true
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/timberio/vector
role: Agent
serviceAccount:
    create: false
    name: platform
tolerations:
    - operator: Exists</code></pre>
</td>
			<td><div>

Vector Agent configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--aggregator">vectorPlatform.aggregator</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>customConfig:
    api:
        address: 0.0.0.0:8686
        enabled: true
        playground: false
    data_dir: /vector-data-dir
    sinks:
        drop_unwanted:
            inputs:
                - log_types.loki
            type: blackhole
        elk_apps:
            auth:
                password: ${ELASTICSEARCH_PASSWORD}
                strategy: basic
                user: elastic
            buffer:
                max_size: 2.68435488e+08
                type: disk
                when_full: drop_newest
            bulk:
                index: application-%Y-%m-%d
            compression: none
            endpoints:
                - http://logsearch-platform.platform.svc.cluster.local.:9200
            inputs:
                - qvantel_apps_no_debug
                - rbs_transform
            tls:
                verify_certificate: false
                verify_hostname: false
            type: elasticsearch
        elk_ingress:
            auth:
                password: ${ELASTICSEARCH_PASSWORD}
                strategy: basic
                user: elastic
            buffer:
                max_size: 2.68435488e+08
                type: disk
                when_full: drop_newest
            bulk:
                index: ingress-%Y-%m-%d
            compression: none
            endpoints:
                - http://logsearch-platform.platform.svc.cluster.local.:9200
            inputs:
                - istio_to_elk_transform
            tls:
                verify_certificate: false
                verify_hostname: false
            type: elasticsearch
        elk_tibco:
            auth:
                password: ${ELASTICSEARCH_PASSWORD}
                strategy: basic
                user: elastic
            buffer:
                max_size: 2.68435488e+08
                type: disk
                when_full: drop_newest
            bulk:
                index: all-tibco-%Y-%m-%d
            compression: none
            endpoints:
                - http://logsearch-platform.platform.svc.cluster.local.:9200
            inputs:
                - tibco_transform
            tls:
                verify_certificate: false
                verify_hostname: false
            type: elasticsearch
        loki:
            buffer:
                max_size: 2.68435488e+08
                type: disk
                when_full: drop_newest
            compression: snappy
            encoding:
                codec: json
            endpoint: http://loki-write.platform.svc.cluster.local.:3100
            inputs:
                - populate_missing_tags_transform
            labels:
                app: '{{ print "{{ kubernetes.pod_labels_app }}" }}'
                artifact_id: '{{ print "{{ artifact_id }}" }}'
                component: '{{ print "{{ kubernetes.pod_labels_component }}" }}'
                forwarder: vector_aggregator
                hostname: '{{ print "{{ kubernetes.hostname }}" }}              '
                instance: '{{ print "{{ kubernetes.pod_labels_instance }}" }}'
                level: '{{ print "{{ log_level }}" }}'
                log_source: '{{ print "{{ log_source }}" }}'
                log_type: '{{ print "{{ log_type }}" }}'
                name: '{{ print "{{ kubernetes.pod_labels_name }}" }}'
                pod_name: '{{ print "{{ kubernetes.pod_name }}" }}'
                pod_namespace: '{{ print "{{ kubernetes.pod_namespace }}" }}'
                pod_node_name: '{{ print "{{ kubernetes.pod_node_name }}" }}'
                service_name: '{{ print "{{ service_name }}" }}'
                severity: '{{ print "{{ severity }}" }}'
                source_type: '{{ print "{{ source_type }}" }}'
            out_of_order_action: accept
            type: loki
        prometheus:
            address: 0.0.0.0:9598
            buffer:
                max_size: 2.68435488e+08
                type: disk
                when_full: drop_newest
            inputs:
                - vector_metrics_transform
            type: prometheus_exporter
    sources:
        k8s_events_fluent:
            address: 0.0.0.0:9002
            mode: tcp
            type: fluent
        logstash:
            address: 0.0.0.0:9000
            type: logstash
        vector:
            address: 0.0.0.0:6000
            type: vector
        vector_logs:
            type: internal_logs
        vector_metrics:
            type: internal_metrics
    transforms:
        cleanup_transform:
            inputs:
                - log_types._unmatched
                - qvantel_apps_transform
                - istio_gateway_transform
                - vault_transform
                - tibco_transform
                - rbs_transform
                - nodes_messages_transform
                - nodes_container_transform
                - nodes_secure_transform
                - vector_logs_transform
                - k8s_events_transform
            source: |
                if exists(.kubernetes.namespace_labels) {
                  del(.kubernetes.namespace_labels)
                }
                if exists(.kubernetes.pod_labels.app) {
                  .kubernetes.pod_labels_app = .kubernetes.pod_labels.app
                }
                if exists(.kubernetes.pod_labels."app.kubernetes.io/instance") {
                  .kubernetes.pod_labels_instance = .kubernetes.pod_labels."app.kubernetes.io/instance"
                }
                if exists(.kubernetes.pod_labels."app.kubernetes.io/name") {
                  .kubernetes.pod_labels_name = .kubernetes.pod_labels."app.kubernetes.io/name"
                }
                if exists(.kubernetes.pod_labels."app.kubernetes.io/component") {
                  .kubernetes.pod_labels_component = .kubernetes.pod_labels."app.kubernetes.io/component"
                }
                if exists(.kubernetes.pod_labels) {
                  del(.kubernetes.pod_labels)
                }
                if exists(.kubernetes.node_labels) {
                  del(.kubernetes.node_labels)
                }
                if exists(.kubernetes.pod_annotations) {
                  del(.kubernetes.pod_annotations)
                }
            type: remap
        istio_gateway_transform:
            inputs:
                - log_types.istio_gateway
            source: ".log_source = \"istio_access_logs\"\nstructured, err = parse_json(.message)\nif err != null {\n  log(\"Unable to parse Istio Access JSON: \" + string!(.message), level: \"error\")\n  .parse_error = err\n} else {\n  .log_type = \"AUDIT\"\n  . = merge!(., structured)\n  parsed_timestamp, err = parse_timestamp(.start_time,\"%+\")\n  if err != null {                  \n    .parse_error = err\n  } else {\n    .timestamp = parsed_timestamp\n  }\n}\n"
            type: remap
        istio_to_elk_transform:
            inputs:
                - istio_gateway_transform
            source: |
                if exists(.kubernetes.pod_labels.app) {
                  .app = .kubernetes.pod_labels.app
                }
                del(.kubernetes)
                .@timestamp = del(.timestamp)
            type: remap
        k8s_events_transform:
            inputs:
                - k8s_events_fluent
            source: |
                .log_source = "k8s-events"
            type: remap
        log_types:
            inputs:
                - vector
                - logstash
            route:
                istio_gateway: .kubernetes.pod_annotations."inject.istio.io/templates" == "gateway"
                loki: .kubernetes.pod_labels."app.kubernetes.io/name" == "loki"
                nodes_container: .tags != null && includes(array!(.tags), "container")
                nodes_messages: .tags != null && includes(array!(.tags), "messages")
                nodes_secure: .tags != null && includes(array!(.tags), "secure")
                qvantel_apps: .kubernetes.pod_namespace == "qvantel"
                rbs: .tags != null && includes(array!(.tags), "rbs")
                tibco: .tags != null && includes(array!(.tags), "tibco")
                vault: .kubernetes.pod_labels."app.kubernetes.io/name" == "vault"
            type: route
        nodes_container_transform:
            inputs:
                - log_types.nodes_container
            source: |
                .log_source = "nodes_containers"
            type: remap
        nodes_messages_transform:
            inputs:
                - log_types.nodes_messages
            source: |
                .log_source = "nodes_messages"
            type: remap
        nodes_secure_transform:
            inputs:
                - log_types.nodes_secure
            source: |
                .log_source = "nodes_secure"
            type: remap
        populate_missing_tags_transform:
            inputs:
                - cleanup_transform
            source: |
                if !exists(.severity) {
                  .severity = ""
                }
                if !exists(.source_type) {
                  .source_type = ""
                }
                if !exists(.log_source) {
                  .log_source = ""
                }
                if !exists(.kubernetes.pod_namespace) {
                  .kubernetes.pod_namespace = ""
                }
                if !exists(.kubernetes.pod_name) {
                  .kubernetes.pod_name = ""
                }
                if !exists(.kubernetes.pod_labels_app) {
                  .kubernetes.pod_labels_app = ""
                }
                if !exists(.kubernetes.pod_labels_instance) {
                  .kubernetes.pod_labels_instance = ""
                }
                if !exists(.kubernetes.pod_labels_name) {
                  .kubernetes.pod_labels_name = ""
                }
                if !exists(.kubernetes.pod_labels_component) {
                  .kubernetes.pod_labels_component = ""
                }
                if !exists(.log_type) {
                  .log_type = ""
                }
                if !exists(.service_name) {
                  .service_name = ""
                }
                if !exists(.artifact_id) {
                  .artifact_id = ""
                }
                if !exists(.log_level) {
                  .log_level = ""
                }
                if !exists(.kubernetes.hostname) {
                  .kubernetes.hostname = ""
                }
                if !exists(.kubernetes.pod_node_name) {
                  .kubernetes.pod_node_name = ""
                }
            type: remap
        qvantel_apps_no_debug:
            condition: |
                .log_level != "DEBUG" && .log_level != "TRACE" && !exists(.parse_error)
            inputs:
                - qvantel_apps_transform
            type: filter
        qvantel_apps_transform:
            inputs:
                - log_types.qvantel_apps
            source: ".log_source = \"qvantel_apps\"\nif .message != null && .message != \"\" {\n  structured, err = parse_json(.message)\n  if err != null {\n    log(\"Unable to parse Qvantel JSON: \" + string!(.message), level: \"error\")\n    .parse_error = err\n  } else {\n    .qvantel_message = .message\n    . = merge!(., structured)\n    parsed_timestamp, err = parse_timestamp(.@timestamp,\"%+\")\n    if err != null {                  \n      .parse_error = err\n    } else {\n      .timestamp = parsed_timestamp\n    }                \n  }\n}        \n"
            type: remap
        rbs_transform:
            inputs:
                - log_types.rbs
            source: |
                .log_source = "rbs_logs"
            type: remap
        tibco_transform:
            inputs:
                - log_types.tibco
            source: |
                .log_source = "tibco_logs"
            type: remap
        vault_transform:
            inputs:
                - log_types.vault
            source: ".log_source = \"vault_audit_logs\"\nstructured, err = parse_json(.message)\nif err != null {\n  log(\"Unable to parse Vault JSON: \" + string!(.message), level: \"error\")\n  .parse_error = err\n} else {\n  .log_type = \"AUDIT\"\n  . = merge!(., structured)\n  parsed_timestamp, err = parse_timestamp(.time,\"%+\")\n  if err != null {                  \n    .parse_error = err\n  } else {\n    .timestamp = parsed_timestamp\n  }\n}\n"
            type: remap
        vector_logs_transform:
            inputs:
                - vector_logs
            source: |
                .log_source = "vector_logs"
            type: remap
        vector_metrics_transform:
            inputs:
                - vector_metrics
            source: |
                del(.tags.file)
            type: remap
enabled: true
env:
    - name: ELASTICSEARCH_PASSWORD
      valueFrom:
        secretKeyRef:
            key: elasticsearch-password
            name: logsearch-elastic
haproxy:
    image:
        repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/haproxytech/haproxy-alpine
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/timberio/vector
role: Aggregator
serviceAccount:
    create: false
    name: platform
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

Vector Aggregator configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--aggregator--customConfig--sinks--drop_unwanted">vectorPlatform.aggregator.customConfig.sinks.drop_unwanted</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>inputs:
    - log_types.loki
type: blackhole</code></pre>
</td>
			<td><div>

Blackhole sink to avoid "has no consumers" warnings

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--aggregator--customConfig--sources">vectorPlatform.aggregator.customConfig.sources</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>k8s_events_fluent:
    address: 0.0.0.0:9002
    mode: tcp
    type: fluent
logstash:
    address: 0.0.0.0:9000
    type: logstash
vector:
    address: 0.0.0.0:6000
    type: vector
vector_logs:
    type: internal_logs
vector_metrics:
    type: internal_metrics</code></pre>
</td>
			<td><div>

Data sources for Vector Aggregator

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--aggregator--customConfig--transforms--cleanup_transform">vectorPlatform.aggregator.customConfig.transforms.cleanup_transform</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>inputs:
    - log_types._unmatched
    - qvantel_apps_transform
    - istio_gateway_transform
    - vault_transform
    - tibco_transform
    - rbs_transform
    - nodes_messages_transform
    - nodes_container_transform
    - nodes_secure_transform
    - vector_logs_transform
    - k8s_events_transform
source: |
    if exists(.kubernetes.namespace_labels) {
      del(.kubernetes.namespace_labels)
    }
    if exists(.kubernetes.pod_labels.app) {
      .kubernetes.pod_labels_app = .kubernetes.pod_labels.app
    }
    if exists(.kubernetes.pod_labels."app.kubernetes.io/instance") {
      .kubernetes.pod_labels_instance = .kubernetes.pod_labels."app.kubernetes.io/instance"
    }
    if exists(.kubernetes.pod_labels."app.kubernetes.io/name") {
      .kubernetes.pod_labels_name = .kubernetes.pod_labels."app.kubernetes.io/name"
    }
    if exists(.kubernetes.pod_labels."app.kubernetes.io/component") {
      .kubernetes.pod_labels_component = .kubernetes.pod_labels."app.kubernetes.io/component"
    }
    if exists(.kubernetes.pod_labels) {
      del(.kubernetes.pod_labels)
    }
    if exists(.kubernetes.node_labels) {
      del(.kubernetes.node_labels)
    }
    if exists(.kubernetes.pod_annotations) {
      del(.kubernetes.pod_annotations)
    }
type: remap</code></pre>
</td>
			<td><div>

Rearranges k8s related labels and discards ones which aren't needed

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--aggregator--customConfig--transforms--istio_to_elk_transform">vectorPlatform.aggregator.customConfig.transforms.istio_to_elk_transform</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>inputs:
    - istio_gateway_transform
source: |
    if exists(.kubernetes.pod_labels.app) {
      .app = .kubernetes.pod_labels.app
    }
    del(.kubernetes)
    .@timestamp = del(.timestamp)
type: remap</code></pre>
</td>
			<td><div>

Transformation in case ELK is enabled - forwards access logs from Istio

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--aggregator--customConfig--transforms--log_types">vectorPlatform.aggregator.customConfig.transforms.log_types</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>inputs:
    - vector
    - logstash
route:
    istio_gateway: .kubernetes.pod_annotations."inject.istio.io/templates" == "gateway"
    loki: .kubernetes.pod_labels."app.kubernetes.io/name" == "loki"
    nodes_container: .tags != null && includes(array!(.tags), "container")
    nodes_messages: .tags != null && includes(array!(.tags), "messages")
    nodes_secure: .tags != null && includes(array!(.tags), "secure")
    qvantel_apps: .kubernetes.pod_namespace == "qvantel"
    rbs: .tags != null && includes(array!(.tags), "rbs")
    tibco: .tags != null && includes(array!(.tags), "tibco")
    vault: .kubernetes.pod_labels."app.kubernetes.io/name" == "vault"
type: route</code></pre>
</td>
			<td><div>

Identifies logs based on tags so transformations can target specific log types

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--aggregator--customConfig--transforms--populate_missing_tags_transform">vectorPlatform.aggregator.customConfig.transforms.populate_missing_tags_transform</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>inputs:
    - cleanup_transform
source: |
    if !exists(.severity) {
      .severity = ""
    }
    if !exists(.source_type) {
      .source_type = ""
    }
    if !exists(.log_source) {
      .log_source = ""
    }
    if !exists(.kubernetes.pod_namespace) {
      .kubernetes.pod_namespace = ""
    }
    if !exists(.kubernetes.pod_name) {
      .kubernetes.pod_name = ""
    }
    if !exists(.kubernetes.pod_labels_app) {
      .kubernetes.pod_labels_app = ""
    }
    if !exists(.kubernetes.pod_labels_instance) {
      .kubernetes.pod_labels_instance = ""
    }
    if !exists(.kubernetes.pod_labels_name) {
      .kubernetes.pod_labels_name = ""
    }
    if !exists(.kubernetes.pod_labels_component) {
      .kubernetes.pod_labels_component = ""
    }
    if !exists(.log_type) {
      .log_type = ""
    }
    if !exists(.service_name) {
      .service_name = ""
    }
    if !exists(.artifact_id) {
      .artifact_id = ""
    }
    if !exists(.log_level) {
      .log_level = ""
    }
    if !exists(.kubernetes.hostname) {
      .kubernetes.hostname = ""
    }
    if !exists(.kubernetes.pod_node_name) {
      .kubernetes.pod_node_name = ""
    }
type: remap</code></pre>
</td>
			<td><div>

Transformation adding labels which loki sink configuration expects to exist

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--aggregator--customConfig--transforms--qvantel_apps_no_debug">vectorPlatform.aggregator.customConfig.transforms.qvantel_apps_no_debug</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>condition: |
    .log_level != "DEBUG" && .log_level != "TRACE" && !exists(.parse_error)
inputs:
    - qvantel_apps_transform
type: filter</code></pre>
</td>
			<td><div>

Transformation in case ELK is enabled - only forwards access logs and app logs which aren't DEBUG or TRACE and could be parsed

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--aggregator--customConfig--transforms--qvantel_apps_transform">vectorPlatform.aggregator.customConfig.transforms.qvantel_apps_transform</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>inputs:
    - log_types.qvantel_apps
source: ".log_source = \"qvantel_apps\"\nif .message != null && .message != \"\" {\n  structured, err = parse_json(.message)\n  if err != null {\n    log(\"Unable to parse Qvantel JSON: \" + string!(.message), level: \"error\")\n    .parse_error = err\n  } else {\n    .qvantel_message = .message\n    . = merge!(., structured)\n    parsed_timestamp, err = parse_timestamp(.@timestamp,\"%+\")\n    if err != null {                  \n      .parse_error = err\n    } else {\n      .timestamp = parsed_timestamp\n    }                \n  }\n}        \n"
type: remap</code></pre>
</td>
			<td><div>

Transformation relying on [Generic Log Format](https://qvantel.atlassian.net/wiki/spaces/PDG/pages/1358727788/Generic+Log+Format) for app logs

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vectorPlatform--fluent-bit-events-collector">vectorPlatform.fluent-bit-events-collector</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>config:
    inputs: |
        [INPUT]
            name kubernetes_events
            tag k8s_events
            # ask k8s API for updates every 30 seconds (default 5)
            interval_sec 30
    outputs: |
        [OUTPUT]
            name forward
            match k8s_events
            host vector-platform-aggregator.platform.svc
            port 9002
enabled: true
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/fluent/fluent-bit
    tag: 4.0.8
kind: Deployment
nameOverride: fluent-bit-events-collector
rbac:
    create: true
    eventsAccess: true
serviceAccount:
    create: false
    name: platform
testFramework:
    enabled: false</code></pre>
</td>
			<td><div>

Fluent Bit configuration

</div>
</td>
		</tr>
	</tbody>
</table>

