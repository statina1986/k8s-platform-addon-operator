

# istio-platform

This module is responsible for deployment of [Istio](https://github.com/istio/istio) control plane to the cluster

Depends on modules:
- None

Provides:
- Istio Control Plane

### Default configuration
Here are important default configs established:
* HTTP Retries are disabled by default, because they are not safe for Qvantel products
* Access Logging for Ingress solution is configured with JSON format including Qvantel specifics like X-Trace-Token

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
			<td style="width: 300px;" id="istioPlatform--base">istioPlatform.base</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>global:
    istioNamespace: platform</code></pre>
</td>
			<td><div>

Configuration for base values. See https://github.com/istio/istio/tree/master/manifests/charts/base

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioPlatform--global">istioPlatform.global</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>proxy:
    image: platform.artifactory.qvantel.net/k8s-platform-1-2-0/istio/proxyv2:1.27.1</code></pre>
</td>
			<td><div>

Configuration for global module values

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioPlatform--istiod">istioPlatform.istiod</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
global:
    istioNamespace: platform
    logAsJson: true
meshConfig:
    defaultHttpRetryPolicy:
        retries:
            attempts: 0
    extensionProviders:
        - envoyFileAccessLog:
            logFormat:
                labels:
                    authority: '%REQ(:AUTHORITY)%'
                    bytes_received: '%BYTES_RECEIVED%'
                    bytes_sent: '%BYTES_SENT%'
                    client_ip: '%REQ(TRUE-Client-IP)%'
                    downstream_local_address: '%DOWNSTREAM_LOCAL_ADDRESS%'
                    downstream_peer_serial: '%DOWNSTREAM_PEER_SERIAL%'
                    downstream_remote_address: '%DOWNSTREAM_REMOTE_ADDRESS%'
                    duration: '%DURATION%'
                    method: '%REQ(:METHOD)%'
                    path: '%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%'
                    protocol: '%PROTOCOL%'
                    request_body: '%DYNAMIC_METADATA(envoy.lua:request_body)%'
                    request_headers: '%DYNAMIC_METADATA(envoy.lua:request_headers)%'
                    request_id: '%REQ(X-REQUEST-ID)%'
                    requested_server_name: '%REQUESTED_SERVER_NAME%'
                    response_body: '%DYNAMIC_METADATA(envoy.lua:response_body)%'
                    response_code: '%RESPONSE_CODE%'
                    response_code_details: '%RESPONSE_CODE_DETAILS%'
                    response_flags: '%RESPONSE_FLAGS%'
                    response_headers: '%DYNAMIC_METADATA(envoy.lua:response_headers)%'
                    route_name: '%ROUTE_NAME%'
                    start_time: '%START_TIME%'
                    upstream_cluster: '%UPSTREAM_CLUSTER%'
                    upstream_host: '%UPSTREAM_HOST%'
                    upstream_local_address: '%UPSTREAM_LOCAL_ADDRESS%'
                    upstream_service_time: '%REQ(X-ENVOY-UPSTREAM_SERVICE_TIME)%'
                    upstream_transport_failure_reason: '%UPSTREAM_TRANSPORT_FAILURE_REASON%'
                    user_agent: '%REQ(USER-AGENT)%'
                    x_forwarded_for: '%REQ(X-FORWARDED-FOR)%'
                    x_trace_token: '%REQ(X-TRACE-TOKEN)%'
                    x_trace_token_resp: '%RESP(X-TRACE-TOKEN)%'
          name: ingress-access-log
pilot:
    image: platform.artifactory.qvantel.net/k8s-platform-1-2-0/istio/pilot:1.27.1
    resources:
        requests:
            cpu: 100m
            memory: 128Mi
    tolerations:
        - effect: NoSchedule
          key: dedicated-nodes
          operator: Equal
          value: platform-masters</code></pre>
</td>
			<td><div>

Configuration for istio-discovery values. See https://github.com/istio/istio/tree/master/manifests/charts/istio-control/istio-discovery

</div>
</td>
		</tr>
	</tbody>
</table>

