

# istio-ingress

This module is responsible for deployment of [Istio](https://github.com/istio/istio) Ingress Gateway solution in the cluster.
This module deploys only Ingress Gateways, not Istio control plane itself

Depends on modules:
- [istio-platform](/modules/150-istio-platform/README.md) which deploys Istio control-plane is required

Provides:
- Several Ingress Gateway deployments
- Virtual Service management
- Set of default Virtual Services for common Qvantel apps
- Access logs with JSON format

Additional documentation can be found in Platform Docs https://intra.qvantel.com/display/QKA/Ingress

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
			<td style="width: 300px;" id="istioIngress--integrationsHttpIngress">istioIngress.integrationsHttpIngress</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>autoscaling:
    enabled: false
    maxReplicas: 9
    minReplicas: 3
    targetCPUUtilizationPercentage: 80
labels:
    istio-ingress: "true"
name: integrations-http-ingress
podAnnotations:
    proxy.istio.io/config: |
        drainDuration: 30s
        terminationDrainDuration: 31s
replicaCount: 3
resources:
    limits:
        memory: 1024Mi
    requests:
        cpu: 100m
        memory: 128Mi
service:
    annotations:
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=some-cluster-i-http
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=false
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        service.beta.kubernetes.io/aws-load-balancer-name: some-cluster-i-http
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        service.beta.kubernetes.io/aws-load-balancer-type: external
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

Configuration for underlying `gateway` helm-chart for Integrations Http Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsHttpIngressBufferHttpRequestSize">istioIngress.integrationsHttpIngressBufferHttpRequestSize</td>
			<td>int</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>0</code></pre>
</td>
			<td><div>

Configure request buffering (in bytes) for Integrations Http Ingress gateway. Set to 0 for disabling buffering.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsHttpIngressEnabled">istioIngress.integrationsHttpIngressEnabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enables Integrations Http Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsHttpIngressGateways">istioIngress.integrationsHttpIngressGateways</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- name: integrations-http-ingress
  spec:
    selector:
        istio: integrations-http-ingress
    servers:
        - hosts:
            - '*'
          port:
            name: http
            number: 80
            protocol: HTTP
        - hosts:
            - '*'
          port:
            name: https
            number: 443
            protocol: HTTPS
          tls:
            credentialName: qvantel-wildcard
            mode: SIMPLE</code></pre>
</td>
			<td><div>

List of  `Gateway` resources provisioned for Integrations Http Ingress gateway.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsHttpIngressLogFullRequest">istioIngress.integrationsHttpIngressLogFullRequest</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable full request logging for Integrations Http Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsHttpIngressLogFullResponse">istioIngress.integrationsHttpIngressLogFullResponse</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable full response logging for Integrations Http Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsNonHttpIngress">istioIngress.integrationsNonHttpIngress</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>autoscaling:
    enabled: false
    maxReplicas: 9
    minReplicas: 3
    targetCPUUtilizationPercentage: 80
labels:
    istio-ingress: "true"
name: integrations-non-http-ingress
podAnnotations:
    proxy.istio.io/config: |
        drainDuration: 30s
        terminationDrainDuration: 31s
replicaCount: 3
resources:
    limits:
        memory: 1024Mi
    requests:
        cpu: 100m
        memory: 128Mi
service:
    annotations:
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=some-cluster-i-nonhttp
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=true
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        service.beta.kubernetes.io/aws-load-balancer-name: some-cluster-i-nonhttp
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        service.beta.kubernetes.io/aws-load-balancer-type: external
    ports:
        - name: status-port
          port: 15021
          protocol: TCP
          targetPort: 15021
        - name: sftp
          port: 22
          protocol: TCP
          targetPort: 22
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

Configuration for underlying `gateway` helm-chart for Integrations Non Http Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsNonHttpIngressBufferHttpRequestSize">istioIngress.integrationsNonHttpIngressBufferHttpRequestSize</td>
			<td>int</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>0</code></pre>
</td>
			<td><div>

Configure request buffering (in bytes) for Integrations Non Http Ingress gateway. Set to 0 for disabling buffering.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsNonHttpIngressEnabled">istioIngress.integrationsNonHttpIngressEnabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enables Integrations Non Http Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsNonHttpIngressGateways">istioIngress.integrationsNonHttpIngressGateways</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- name: integrations-non-http-ingress
  spec:
    selector:
        istio: integrations-non-http-ingress
    servers:
        - hosts:
            - '*'
          port:
            name: sftp
            number: 22
            protocol: TCP</code></pre>
</td>
			<td><div>

List of  `Gateway` resources provisioned for Integrations Non Http Ingress gateway.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsNonHttpIngressLogFullRequest">istioIngress.integrationsNonHttpIngressLogFullRequest</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable full request logging for Integrations Non Http Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--integrationsNonHttpIngressLogFullResponse">istioIngress.integrationsNonHttpIngressLogFullResponse</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable full response logging for Integrations Non Http Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--pomeriumEnabled">istioIngress.pomeriumEnabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enables Pomerium Authorization proxy. This will affect only VirtualServices which have `pomeriumProtected: true` attributes

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--privateIngress">istioIngress.privateIngress</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>autoscaling:
    enabled: false
    maxReplicas: 9
    minReplicas: 3
    targetCPUUtilizationPercentage: 80
labels:
    istio-ingress: "true"
name: private-ingress
podAnnotations:
    proxy.istio.io/config: |
        drainDuration: 30s
        terminationDrainDuration: 31s
replicaCount: 3
resources:
    limits:
        memory: 1024Mi
    requests:
        cpu: 100m
        memory: 128Mi
service:
    annotations:
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=some-cluster-i-private
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=false
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        service.beta.kubernetes.io/aws-load-balancer-name: some-cluster-i-private
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        service.beta.kubernetes.io/aws-load-balancer-type: external
    ports:
        - name: status-port
          port: 15021
          protocol: TCP
          targetPort: 15021
        - name: http
          port: 80
          protocol: TCP
          targetPort: 80
        - name: https
          port: 443
          protocol: TCP
          targetPort: 443
        - name: rabbitmq
          port: 5672
          protocol: TCP
          targetPort: 5672
        - name: rabbitmq-stomp
          port: 61613
          protocol: TCP
          targetPort: 61613
        - name: rabbitmq-webstomp
          port: 15674
          protocol: TCP
          targetPort: 15674
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

Configuration for underlying `gateway` helm-chart for Private Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--privateIngressBufferHttpRequestSize">istioIngress.privateIngressBufferHttpRequestSize</td>
			<td>int</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>0</code></pre>
</td>
			<td><div>

Configure request buffering (in bytes) for Private Ingress gateway. Set to 0 for disabling buffering.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--privateIngressEnabled">istioIngress.privateIngressEnabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enables Private Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--privateIngressGateways">istioIngress.privateIngressGateways</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- name: private-ingress
  spec:
    selector:
        istio: private-ingress
    servers:
        - hosts:
            - '*'
          port:
            name: http
            number: 80
            protocol: HTTP
        - hosts:
            - '*'
          port:
            name: https
            number: 443
            protocol: HTTPS
          tls:
            credentialName: qvantel-wildcard
            mode: SIMPLE
        - hosts:
            - '*'
          port:
            name: rabbitmq
            number: 5672
            protocol: TCP
        - hosts:
            - '*'
          port:
            name: rabbitmq-stomp
            number: 61613
            protocol: TCP
        - hosts:
            - '*'
          port:
            name: rabbitmq-webstomp
            number: 15674
            protocol: HTTP</code></pre>
</td>
			<td><div>

List of  `Gateway` resources provisioned for Private Ingress gateway.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--privateIngressLogFullRequest">istioIngress.privateIngressLogFullRequest</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable full request logging for Private Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--privateIngressLogFullResponse">istioIngress.privateIngressLogFullResponse</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable full response logging for Private Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--publicIngress">istioIngress.publicIngress</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>autoscaling:
    enabled: false
    maxReplicas: 9
    minReplicas: 3
    targetCPUUtilizationPercentage: 80
labels:
    istio-ingress: "true"
name: public-ingress
podAnnotations:
    proxy.istio.io/config: |
        drainDuration: 30s
        terminationDrainDuration: 31s
replicaCount: 3
resources:
    limits:
        memory: 1024Mi
    requests:
        cpu: 100m
        memory: 128Mi
service:
    annotations:
        service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: Name=some-cluster-i-public
        service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=false
        service.beta.kubernetes.io/aws-load-balancer-internal: "false"
        service.beta.kubernetes.io/aws-load-balancer-name: some-cluster-i-public
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
        service.beta.kubernetes.io/aws-load-balancer-type: external
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters</code></pre>
</td>
			<td><div>

Configuration for underlying `gateway` helm-chart for Public Ingress gateway. See https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--publicIngressBufferHttpRequestSize">istioIngress.publicIngressBufferHttpRequestSize</td>
			<td>int</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>0</code></pre>
</td>
			<td><div>

Configure request buffering (in bytes) for Public Ingress gateway. Set to 0 for disabling buffering.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--publicIngressEnabled">istioIngress.publicIngressEnabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enables Public Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--publicIngressGateways">istioIngress.publicIngressGateways</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- name: public-ingress
  spec:
    selector:
        istio: public-ingress
    servers:
        - hosts:
            - '*'
          port:
            name: http
            number: 80
            protocol: HTTP
        - hosts:
            - '*'
          port:
            name: https
            number: 443
            protocol: HTTPS
          tls:
            credentialName: qvantel-wildcard
            mode: SIMPLE</code></pre>
</td>
			<td><div>

List of  `Gateway` resources provisioned for Public Ingress gateway.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--publicIngressLogFullRequest">istioIngress.publicIngressLogFullRequest</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable full request logging for Public Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--publicIngressLogFullResponse">istioIngress.publicIngressLogFullResponse</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable full response logging for Public Ingress gateway

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--virtualServices">istioIngress.virtualServices</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>see values.yaml.mako</code></pre>
</td>
			<td><div>

VirtualServices to be provisioned.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--virtualServices--annotations">istioIngress.virtualServices.annotations</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>null</code></pre>
</td>
			<td><div>

Common annotations for all VirtualServices resources provisioned

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--virtualServices--appsNamespace">istioIngress.virtualServices.appsNamespace</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>qvantel</code></pre>
</td>
			<td><div>

Qvantel applications namespace name. By default value is taken from `global.appsNamespace` and equal to `qvantel`

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--virtualServices--dnsBase">istioIngress.virtualServices.dnsBase</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>-some-env.qvantel.solutions</code></pre>
</td>
			<td><div>

Common base dns name to be used for all VirtualServices. `host` of VirtualServices will be set to <virtual-service-name><dnsSeparator><dnsBase>. By default values are taken from `global.ingressBaseUrl` and `global.ingressBaseUrlSeparator`

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--virtualServices--instances">istioIngress.virtualServices.instances</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>see values.yaml.mako</code></pre>
</td>
			<td><div>

List of  `VirtualService` resources to be provisioned. It is a map, so it can be configuration may be inherited/extended in multiple valyes.yaml files. 

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="istioIngress--virtualServices--platformNamespace">istioIngress.virtualServices.platformNamespace</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>platform</code></pre>
</td>
			<td><div>

Qvantel platform namespace name. By default value is taken from `global.appsNamespace` and equal to `platform`

</div>
</td>
		</tr>
	</tbody>
</table>

