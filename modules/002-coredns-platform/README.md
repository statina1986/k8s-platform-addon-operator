

# coredns-platform

This module is responsible for deployment of [coredns-platform](https://coredns.io/manual/toc/) in the cluster.
This module exposes a new customizable Corefile and doesn't remove any original coredns resources.

Depends on modules:
- no dependencies

Used helm-charts:
- coredns : 1.45.0

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
			<td style="width: 300px;" id="corednsPlatform--coredns">corednsPlatform.coredns</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>autoscaler:
    image:
        repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/cpa/cluster-proportional-autoscaler
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/coredns/coredns
k8sAppLabelOverride: kube-dns
replicaCount: 2
resources:
    limits:
        cpu: 200m
        memory: 256Mi
    requests:
        cpu: 100m
        memory: 128Mi
servers:
    - name: default
      plugins:
        - name: errors
        - configBlock: lameduck 10s
          name: health
        - name: ready
        - configBlock: |-
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
          name: kubernetes
          parameters: cluster.local in-addr.arpa ip6.arpa
        - name: prometheus
          parameters: 0.0.0.0:9153
        - name: forward
          parameters: . /etc/resolv.conf
        - name: cache
          parameters: 30
        - name: loop
        - name: reload
        - name: loadbalance
      port: 53
      zones:
        - use_tcp: true
          zone: .</code></pre>
</td>
			<td><div>

Configuration for underlying coredns helm-chart. See https://github.com/coredns/helm/tree/master/charts/coredns

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="corednsPlatform--coredns--k8sAppLabelOverride">corednsPlatform.coredns.k8sAppLabelOverride</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>kube-dns</code></pre>
</td>
			<td><div>

Label selector for the pod, used by the the original coredns service.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="corednsPlatform--coredns--servers">corednsPlatform.coredns.servers</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- name: default
  plugins:
    - name: errors
    - configBlock: lameduck 10s
      name: health
    - name: ready
    - configBlock: |-
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
        ttl 30
      name: kubernetes
      parameters: cluster.local in-addr.arpa ip6.arpa
    - name: prometheus
      parameters: 0.0.0.0:9153
    - name: forward
      parameters: . /etc/resolv.conf
    - name: cache
      parameters: 30
    - name: loop
    - name: reload
    - name: loadbalance
  port: 53
  zones:
    - use_tcp: true
      zone: .</code></pre>
</td>
			<td><div>

List of zones. Default zone only applied when no zones are configured.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="corednsPlatform--overrideSystemCoredns">corednsPlatform.overrideSystemCoredns</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

Override and scale down the original coredns.

</div>
</td>
		</tr>
	</tbody>
</table>

