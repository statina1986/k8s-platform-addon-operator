

# cert-platform

This module is responsible for deployment of [cert-manager](https://cert-manager.io/docs/) in the cluster and configuration of required platform certificates

Depends on modules:
- no dependencies

Used helm-charts:
- cert-manager : v1.12.13

# Qvantel AWS Usage

When runnig in Qvantel Managed AWS environments this module is capable to automatically provision LetsEncrypt certificates for Qvantel domains `*.qvantel.systems` or `*.qvantel.solutions`.
Respective issuers and certificates should be enabled in the configuration. See available configuration options below.

## Values

<h3> Main Values</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
	<tr>
		<td style="width: 300px;">certPlatform.cert-manager</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>acmesolver:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: jetstack/cert-manager-acmesolver
cainjector:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: jetstack/cert-manager-cainjector
    serviceAccount:
        create: false
        name: platform
enabled: true
extraArgs:
    - --issuer-ambient-credentials
global:
    leaderElection:
        namespace: platform
image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    repository: jetstack/cert-manager-controller
serviceAccount:
    create: false
    name: platform
startupapicheck:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: jetstack/cert-manager-ctl
    serviceAccount:
        create: false
        name: platform
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters
webhook:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: jetstack/cert-manager-webhook
    serviceAccount:
        create: false
        name: platform</code></pre>
</td>
		<td>
<div>

Configuration for underlying cert-manager helm-chart. See https://artifacthub.io/packages/helm/cert-manager/cert-manager/1.12.13#configuration

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.certificates</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>qvantel-ca:
    enabled: true
    spec:
        commonName: qvantel.com
        duration: 87660h
        isCA: true
        issuerRef:
            group: cert-manager.io
            kind: Issuer
            name: qvantel-selfsigned-issuer
        privateKey:
            algorithm: ECDSA
            size: 256
        renewBefore: 360h
        secretName: qvantel-root-ca
        subject:
            organizations:
                - Qvantel Oy
qvantel-dot-solutions-wildcard:
    enabled: false
    spec:
        dnsNames:
            - '*.qvantel.solutions'
            - qvantel.solutions
        issuerRef:
            group: cert-manager.io
            kind: Issuer
            name: qvantel-dot-solutions
        privateKey:
            rotationPolicy: Always
        renewBefore: 720h
        secretName: qvantel-wildcard
qvantel-dot-systems-wildcard:
    enabled: false
    spec:
        dnsNames:
            - '*.qvantel.systems'
            - qvantel.systems
        issuerRef:
            group: cert-manager.io
            kind: Issuer
            name: qvantel-dot-systems
        privateKey:
            rotationPolicy: Always
        renewBefore: 720h
        secretName: qvantel-wildcard</code></pre>
</td>
		<td>
<div>

List of Certificates to provision. See https://cert-manager.io/docs/usage/certificate/ for `Certificate` resource details.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.certificates.qvantel-ca</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
spec:
    commonName: qvantel.com
    duration: 87660h
    isCA: true
    issuerRef:
        group: cert-manager.io
        kind: Issuer
        name: qvantel-selfsigned-issuer
    privateKey:
        algorithm: ECDSA
        size: 256
    renewBefore: 360h
    secretName: qvantel-root-ca
    subject:
        organizations:
            - Qvantel Oy</code></pre>
</td>
		<td>
<div>

This is the root CA certificate for Simple Qvantel CA

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.certificates.qvantel-dot-solutions-wildcard</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec:
    dnsNames:
        - '*.qvantel.solutions'
        - qvantel.solutions
    issuerRef:
        group: cert-manager.io
        kind: Issuer
        name: qvantel-dot-solutions
    privateKey:
        rotationPolicy: Always
    renewBefore: 720h
    secretName: qvantel-wildcard</code></pre>
</td>
		<td>
<div>

This is the wildcard certificate issued for *.qvantel.solutions name

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.certificates.qvantel-dot-systems-wildcard</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec:
    dnsNames:
        - '*.qvantel.systems'
        - qvantel.systems
    issuerRef:
        group: cert-manager.io
        kind: Issuer
        name: qvantel-dot-systems
    privateKey:
        rotationPolicy: Always
    renewBefore: 720h
    secretName: qvantel-wildcard</code></pre>
</td>
		<td>
<div>

This is the wildcard certificate issued for *.qvantel.systems name

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.clusterIssuers</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>example-cluster-issuer:
    enabled: false
    spec: {}</code></pre>
</td>
		<td>
<div>

List of ClusterIssuers to provision. See https://cert-manager.io/docs/concepts/issuer/ for `ClusterIssuer` resource details.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.clusterIssuers.example-cluster-issuer</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec: {}</code></pre>
</td>
		<td>
<div>

Example ClusterIssuer used for documentation

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.clusterIssuers.example-cluster-issuer.enabled</td>
		<td>bool</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
		<td>
<div>

If ClusterIssuers is enabled and hence will be deployed to the cluster.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.clusterIssuers.example-cluster-issuer.spec</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td>
<div>

Configure `spec` property of `ClusterIssuers` resource.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.issuers</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>example-issuer:
    enabled: false
    spec: {}
qvantel-ca-issuer:
    enabled: true
    spec:
        ca:
            secretName: qvantel-root-ca
qvantel-dot-solutions:
    enabled: false
    spec:
        acme:
            email: infra.finland@qvantel.com
            privateKeySecretRef:
                name: qvantel-dot-solutions-private-key-letsencrypt
            server: https://acme-v02.api.letsencrypt.org./directory
            solvers:
                - dns01:
                    route53:
                        hostedZoneID: ZPXWBK7RK86EX
                        region: eu-central-1
                        role: arn:aws:iam::067412573140:role/Update-Qvantel-Solutions-DNS-From-Prod-Accounts
                  selector:
                    dnsZones:
                        - qvantel.solutions
qvantel-dot-systems:
    enabled: false
    spec:
        acme:
            email: infra.finland@qvantel.com
            privateKeySecretRef:
                name: letsencrypt-platform-dns
            server: https://acme-v02.api.letsencrypt.org./directory
            solvers:
                - dns01:
                    route53:
                        hostedZoneID: ZJ7W7ERY57J33
                        region: eu-central-1
                        role: arn:aws:iam::067412573140:role/Qvantel-Update-DNS-From-Development-Account
                  selector:
                    dnsZones:
                        - qvantel.systems
qvantel-selfsigned-issuer:
    enabled: true
    spec:
        selfSigned: {}</code></pre>
</td>
		<td>
<div>

List of Issuers to provision. See https://cert-manager.io/docs/concepts/issuer/ for `Issuer` resource details.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.issuers.example-issuer</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec: {}</code></pre>
</td>
		<td>
<div>

Example Issuer used for documentation

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.issuers.example-issuer.enabled</td>
		<td>bool</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
		<td>
<div>

If Issuer is enabled and hence will be deployed to the cluster.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.issuers.example-issuer.spec</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td>
<div>

Configure `spec` property of `Issuer` resource.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.issuers.qvantel-ca-issuer</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
spec:
    ca:
        secretName: qvantel-root-ca</code></pre>
</td>
		<td>
<div>

This issuer is Simple Qvantel CA issuer

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.issuers.qvantel-dot-solutions</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec:
    acme:
        email: infra.finland@qvantel.com
        privateKeySecretRef:
            name: qvantel-dot-solutions-private-key-letsencrypt
        server: https://acme-v02.api.letsencrypt.org./directory
        solvers:
            - dns01:
                route53:
                    hostedZoneID: ZPXWBK7RK86EX
                    region: eu-central-1
                    role: arn:aws:iam::067412573140:role/Update-Qvantel-Solutions-DNS-From-Prod-Accounts
              selector:
                dnsZones:
                    - qvantel.solutions</code></pre>
</td>
		<td>
<div>

This issuer is used for *.qvantel.solutions certificates issued with letsencrypt

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.issuers.qvantel-dot-systems</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec:
    acme:
        email: infra.finland@qvantel.com
        privateKeySecretRef:
            name: letsencrypt-platform-dns
        server: https://acme-v02.api.letsencrypt.org./directory
        solvers:
            - dns01:
                route53:
                    hostedZoneID: ZJ7W7ERY57J33
                    region: eu-central-1
                    role: arn:aws:iam::067412573140:role/Qvantel-Update-DNS-From-Development-Account
              selector:
                dnsZones:
                    - qvantel.systems</code></pre>
</td>
		<td>
<div>

This issuer is used for *.qvantel.systems certificates issued with letsencrypt

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">certPlatform.issuers.qvantel-selfsigned-issuer</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
spec:
    selfSigned: {}</code></pre>
</td>
		<td>
<div>

This issuer is used to generate self-signed certificate for Simple Qvantel CA

</div>
		</td>
	</tr>
	</tbody>
</table>

<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;" id="certPlatform--cert-manager">certPlatform.cert-manager</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>acmesolver:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: jetstack/cert-manager-acmesolver
cainjector:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: jetstack/cert-manager-cainjector
    serviceAccount:
        create: false
        name: platform
enabled: true
extraArgs:
    - --issuer-ambient-credentials
global:
    leaderElection:
        namespace: platform
image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    repository: jetstack/cert-manager-controller
serviceAccount:
    create: false
    name: platform
startupapicheck:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: jetstack/cert-manager-ctl
    serviceAccount:
        create: false
        name: platform
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters
webhook:
    image:
        registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
        repository: jetstack/cert-manager-webhook
    serviceAccount:
        create: false
        name: platform</code></pre>
</div>
			</td>
			<td>
<div>

Configuration for underlying cert-manager helm-chart. See https://artifacthub.io/packages/helm/cert-manager/cert-manager/1.12.13#configuration

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--certificates">certPlatform.certificates</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>qvantel-ca:
    enabled: true
    spec:
        commonName: qvantel.com
        duration: 87660h
        isCA: true
        issuerRef:
            group: cert-manager.io
            kind: Issuer
            name: qvantel-selfsigned-issuer
        privateKey:
            algorithm: ECDSA
            size: 256
        renewBefore: 360h
        secretName: qvantel-root-ca
        subject:
            organizations:
                - Qvantel Oy
qvantel-dot-solutions-wildcard:
    enabled: false
    spec:
        dnsNames:
            - '*.qvantel.solutions'
            - qvantel.solutions
        issuerRef:
            group: cert-manager.io
            kind: Issuer
            name: qvantel-dot-solutions
        privateKey:
            rotationPolicy: Always
        renewBefore: 720h
        secretName: qvantel-wildcard
qvantel-dot-systems-wildcard:
    enabled: false
    spec:
        dnsNames:
            - '*.qvantel.systems'
            - qvantel.systems
        issuerRef:
            group: cert-manager.io
            kind: Issuer
            name: qvantel-dot-systems
        privateKey:
            rotationPolicy: Always
        renewBefore: 720h
        secretName: qvantel-wildcard</code></pre>
</div>
			</td>
			<td>
<div>

List of Certificates to provision. See https://cert-manager.io/docs/usage/certificate/ for `Certificate` resource details.

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--certificates--qvantel-ca">certPlatform.certificates.qvantel-ca</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
spec:
    commonName: qvantel.com
    duration: 87660h
    isCA: true
    issuerRef:
        group: cert-manager.io
        kind: Issuer
        name: qvantel-selfsigned-issuer
    privateKey:
        algorithm: ECDSA
        size: 256
    renewBefore: 360h
    secretName: qvantel-root-ca
    subject:
        organizations:
            - Qvantel Oy</code></pre>
</div>
			</td>
			<td>
<div>

This is the root CA certificate for Simple Qvantel CA

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--certificates--qvantel-dot-solutions-wildcard">certPlatform.certificates.qvantel-dot-solutions-wildcard</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec:
    dnsNames:
        - '*.qvantel.solutions'
        - qvantel.solutions
    issuerRef:
        group: cert-manager.io
        kind: Issuer
        name: qvantel-dot-solutions
    privateKey:
        rotationPolicy: Always
    renewBefore: 720h
    secretName: qvantel-wildcard</code></pre>
</div>
			</td>
			<td>
<div>

This is the wildcard certificate issued for *.qvantel.solutions name

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--certificates--qvantel-dot-systems-wildcard">certPlatform.certificates.qvantel-dot-systems-wildcard</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec:
    dnsNames:
        - '*.qvantel.systems'
        - qvantel.systems
    issuerRef:
        group: cert-manager.io
        kind: Issuer
        name: qvantel-dot-systems
    privateKey:
        rotationPolicy: Always
    renewBefore: 720h
    secretName: qvantel-wildcard</code></pre>
</div>
			</td>
			<td>
<div>

This is the wildcard certificate issued for *.qvantel.systems name

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--clusterIssuers">certPlatform.clusterIssuers</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>example-cluster-issuer:
    enabled: false
    spec: {}</code></pre>
</div>
			</td>
			<td>
<div>

List of ClusterIssuers to provision. See https://cert-manager.io/docs/concepts/issuer/ for `ClusterIssuer` resource details.

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--clusterIssuers--example-cluster-issuer">certPlatform.clusterIssuers.example-cluster-issuer</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec: {}</code></pre>
</div>
			</td>
			<td>
<div>

Example ClusterIssuer used for documentation

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--clusterIssuers--example-cluster-issuer--enabled">certPlatform.clusterIssuers.example-cluster-issuer.enabled</td>
			<td>bool</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</div>
			</td>
			<td>
<div>

If ClusterIssuers is enabled and hence will be deployed to the cluster.

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--clusterIssuers--example-cluster-issuer--spec">certPlatform.clusterIssuers.example-cluster-issuer.spec</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</div>
			</td>
			<td>
<div>

Configure `spec` property of `ClusterIssuers` resource.

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--issuers">certPlatform.issuers</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>example-issuer:
    enabled: false
    spec: {}
qvantel-ca-issuer:
    enabled: true
    spec:
        ca:
            secretName: qvantel-root-ca
qvantel-dot-solutions:
    enabled: false
    spec:
        acme:
            email: infra.finland@qvantel.com
            privateKeySecretRef:
                name: qvantel-dot-solutions-private-key-letsencrypt
            server: https://acme-v02.api.letsencrypt.org./directory
            solvers:
                - dns01:
                    route53:
                        hostedZoneID: ZPXWBK7RK86EX
                        region: eu-central-1
                        role: arn:aws:iam::067412573140:role/Update-Qvantel-Solutions-DNS-From-Prod-Accounts
                  selector:
                    dnsZones:
                        - qvantel.solutions
qvantel-dot-systems:
    enabled: false
    spec:
        acme:
            email: infra.finland@qvantel.com
            privateKeySecretRef:
                name: letsencrypt-platform-dns
            server: https://acme-v02.api.letsencrypt.org./directory
            solvers:
                - dns01:
                    route53:
                        hostedZoneID: ZJ7W7ERY57J33
                        region: eu-central-1
                        role: arn:aws:iam::067412573140:role/Qvantel-Update-DNS-From-Development-Account
                  selector:
                    dnsZones:
                        - qvantel.systems
qvantel-selfsigned-issuer:
    enabled: true
    spec:
        selfSigned: {}</code></pre>
</div>
			</td>
			<td>
<div>

List of Issuers to provision. See https://cert-manager.io/docs/concepts/issuer/ for `Issuer` resource details.

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--issuers--example-issuer">certPlatform.issuers.example-issuer</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec: {}</code></pre>
</div>
			</td>
			<td>
<div>

Example Issuer used for documentation

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--issuers--example-issuer--enabled">certPlatform.issuers.example-issuer.enabled</td>
			<td>bool</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</div>
			</td>
			<td>
<div>

If Issuer is enabled and hence will be deployed to the cluster.

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--issuers--example-issuer--spec">certPlatform.issuers.example-issuer.spec</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</div>
			</td>
			<td>
<div>

Configure `spec` property of `Issuer` resource.

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--issuers--qvantel-ca-issuer">certPlatform.issuers.qvantel-ca-issuer</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
spec:
    ca:
        secretName: qvantel-root-ca</code></pre>
</div>
			</td>
			<td>
<div>

This issuer is Simple Qvantel CA issuer

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--issuers--qvantel-dot-solutions">certPlatform.issuers.qvantel-dot-solutions</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec:
    acme:
        email: infra.finland@qvantel.com
        privateKeySecretRef:
            name: qvantel-dot-solutions-private-key-letsencrypt
        server: https://acme-v02.api.letsencrypt.org./directory
        solvers:
            - dns01:
                route53:
                    hostedZoneID: ZPXWBK7RK86EX
                    region: eu-central-1
                    role: arn:aws:iam::067412573140:role/Update-Qvantel-Solutions-DNS-From-Prod-Accounts
              selector:
                dnsZones:
                    - qvantel.solutions</code></pre>
</div>
			</td>
			<td>
<div>

This issuer is used for *.qvantel.solutions certificates issued with letsencrypt

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--issuers--qvantel-dot-systems">certPlatform.issuers.qvantel-dot-systems</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false
spec:
    acme:
        email: infra.finland@qvantel.com
        privateKeySecretRef:
            name: letsencrypt-platform-dns
        server: https://acme-v02.api.letsencrypt.org./directory
        solvers:
            - dns01:
                route53:
                    hostedZoneID: ZJ7W7ERY57J33
                    region: eu-central-1
                    role: arn:aws:iam::067412573140:role/Qvantel-Update-DNS-From-Development-Account
              selector:
                dnsZones:
                    - qvantel.systems</code></pre>
</div>
			</td>
			<td>
<div>

This issuer is used for *.qvantel.systems certificates issued with letsencrypt

</div>
      </td>
		</tr>
		<tr>
			<td style="width: 300px;" id="certPlatform--issuers--qvantel-selfsigned-issuer">certPlatform.issuers.qvantel-selfsigned-issuer</td>
			<td>object</td>
			<td>
				<div>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
spec:
    selfSigned: {}</code></pre>
</div>
			</td>
			<td>
<div>

This issuer is used to generate self-signed certificate for Simple Qvantel CA

</div>
      </td>
		</tr>
	</tbody>
</table>

