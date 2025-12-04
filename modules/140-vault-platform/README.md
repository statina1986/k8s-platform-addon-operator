

# vault-platform

This module is responsible for deployment of [vault](https://www.vaultproject.io/) in the cluster

Depends on modules:
- [cert-platform](/modules/101-cert-platform/README.md) which is needed to establish vault certificates

Customizations:
- `vault-secrets-webhook` image (`ghcr.io/bank-vaults/vault-secrets-webhook` ) is replaced with Qvantel fork https://stash.qvantel.net/projects/CP/repos/qvantel-vault-secrets-webhook/browse

Provides:
- Vault deployment
- Auto-Initialization
- Auto-Unsealing
- Default secrets engines:
  - KV (v1) engine at path *secret*
  - Database engine at path *database*
- Vault UI
- Manage of Vault entities with CRDs

Vault is available at:
- vault-platform.platform.svc
- vault-platform-active.platform.svc (current vault leader)

Vault UI is available at:
- vault-platform-ui.platform.svc

### Auto initialization
Module is deployed with auto-initialization feature which is capable to auto-initialize **vault**.
If Cloud KMS auto-unseal feature is not used, Shamir keys will be stored in K8S secret.

### Auto-unsealing
Module supports auto-unsealing in 2 scenarios:
- Auto-unseal with cloud KMS. See https://developer.hashicorp.com/vault/docs/concepts/seal#auto-unseal
- Auto-unseal with local K8S secretes

**Cloud KMS auto-unseal**. It is possible to configure module to use auto-unsealing feature with external secrets service, e.g. AWS KMS:
* AWS KMS. In this case following is needed: 
  * This Module uses `platform` Service Account for Vault by default. This service account should be annotated with AWS role, which has permissions to access AWS KMS key
  * Configuration should enable auto-unsealing automation (it is **false** by default) :
    ```
    vaultPlatform:
      autoUnseal: true
    ```
  * **vault** server config should contain auto-unseal block containing KMS key id, e.g.
    ```
    seal "awskms" {
        region     = "eu-central-1"
        kms_key_id = "arn:aws:kms:eu-central-1:386844351831:key/mrk-a123090215d7415ab37eb27d76f4f35d"
    }
    ```
    This is easy to add with ".Values.vault.ha.raft.additionalConfig" parameter. See [values.yaml](values.yaml)
* For details of other types of Cloud KMS services see https://developer.hashicorp.com/vault/tutorials/auto-unseal

**Local K8S secrets auto-unseal**. Usually in on-prem environments Cloud KMS services are not available. If module is configured without external secrets service auto-unsealing (`autoUnseal: false`) then it is possible to auto-unseal vault from Shamir keys stored in local K8S secret with following configuration:

```
vaultPlatform:
  k8sUnseal: true
```

### Manage vault entities with CRDs
Provides configuration of following Vault entities via CRDs:
- [Kubernetes auth method role](./resources/kubernetes-auth-role.yaml)
- [Database secret engine connection](./resources/db-connection.yaml)
- [Database secret engine role](./resources/db-role.yaml)
- [ACL policy](./resources/acl-policy.yaml)
- [K/V Secrets(v1)](./resources/kv1-secret.yaml)

For details of each resource please check CRD definition.

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
			<td style="width: 300px;" id="vaultPlatform--additionalAppsPolicies">vaultPlatform.additionalAppsPolicies</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>""</code></pre>
</td>
			<td><div>

Configuration for additional entries to be added to apps-default-policy.yaml. See [apps-default-policy](templates/apps-default-policy.yaml)

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--autoUnseal">vaultPlatform.autoUnseal</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable auto unseal with external Cloud secrets service (KMS). See https://developer.hashicorp.com/vault/docs/concepts/seal#auto-unseal

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--k8sUnseal">vaultPlatform.k8sUnseal</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable auto unseal with local Shamir keys stored in local K8S secret

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--useBackwardsCompatibilityService">vaultPlatform.useBackwardsCompatibilityService</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

Creates `vault.{{.Release.Namespace}}.svc` which is expected by Qvantel apps

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vault">vaultPlatform.vault</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>global:
    enabled: true
injector:
    enabled: false
server:
    affinity: |
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app.kubernetes.io/name: {{ template "vault.name" . }}
                  app.kubernetes.io/instance: "{{ .Release.Name }}"
                  component: server
              topologyKey: kubernetes.io/hostname
    extraContainers:
        - args:
            - /init-script/init.sh
          command:
            - /bin/sh
          env:
            - name: VAULT_K8S_POD_NAME
              valueFrom:
                fieldRef:
                    apiVersion: v1
                    fieldPath: metadata.name
            - name: VAULT_K8S_NAMESPACE
              valueFrom:
                fieldRef:
                    apiVersion: v1
                    fieldPath: metadata.namespace
            - name: VAULT_INIT_NODE
              value: vault-platform-0
          image: platform.artifactory.qvantel.net/k8s-platform-1-2-0/platform/platform-k8s-tools-minimal:1.3.3_202509080945_master_90384dcc
          imagePullPolicy: IfNotPresent
          name: auto-init-and-unseal-sidecar
          volumeMounts:
            - mountPath: /init-script/
              name: userconfig-vault-auto-init-config
    extraVolumes:
        - defaultMode: 511
          name: vault-auto-init-config
          type: configMap
    ha:
        enabled: true
        limits:
            memory: 1Gi
        raft:
            additionalConfig: ""
            config: |
                ui = true
                listener "tcp" {
                  address = "[::]:8200"
                  cluster_address = "[::]:8201"
                  tls_disable = "true"
                  telemetry {
                    unauthenticated_metrics_access = "true"
                  }
                }
                telemetry {
                  prometheus_retention_time = "30s"
                  disable_hostname = true
                }
                storage "raft" {
                  path = "/vault/data"
                    retry_join {
                    leader_api_addr = "http://vault-platform-0.vault-platform-internal.platform.svc.cluster.local.:8200"
                  }
                  retry_join {
                    leader_api_addr = "http://vault-platform-1.vault-platform-internal.platform.svc.cluster.local.:8200"
                  }
                  retry_join {
                    leader_api_addr = "http://vault-platform-2.vault-platform-internal.platform.svc.cluster.local.:8200"
                  }
                  autopilot {
                    cleanup_dead_servers = "true"
                    last_contact_threshold = "200ms"
                    last_contact_failure_threshold = "10m"
                    max_trailing_logs = 250000
                    min_quorum = 5
                    server_stabilization_time = "10s"
                  }
                }
                service_registration "kubernetes" {}
                {{ .Values.server.ha.raft.additionalConfig}}
            enabled: true
            setNodeId: true
        replicas: 3
        requests:
            cpu: 100m
            memory: 100Mi
    image:
        repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/hashicorp/vault
    livenessProbe:
        enabled: true
        initialDelaySeconds: 60
        path: /v1/sys/health?standbyok=true&sealedcode=503
    readinessProbe:
        enabled: true
        path: /v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204
    resources: {}
    serviceAccount:
        create: false
        name: platform
    standalone:
        config: |
            ui = true
            listener "tcp" {
              tls_disable = 1
              address = "[::]:8200"
              cluster_address = "[::]:8201"
              # Enable unauthenticated metrics access (necessary for Prometheus Operator)
              telemetry {
                unauthenticated_metrics_access = "true"
              }
            }
            storage "file" {
              path = "/vault/data"
            }
            telemetry {
              prometheus_retention_time = "30s"
              disable_hostname = true
            }
    tolerations: |
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
serverTelemetry:
    serviceMonitor:
        enabled: true
        selectors:
            release: monitoring-platform</code></pre>
</td>
			<td><div>

Configuration for underlying vault helm-chart. See https://developer.hashicorp.com/vault/docs/platform/k8s/helm/configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vault-secrets-webhook">vaultPlatform.vault-secrets-webhook</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>certificate:
    generate: false
    servingCertificate: vault-platform-vault-secrets-webhook-ca
    useCertManager: false
configMapFailurePolicy: Fail
ignoreReleaseNamespace: false
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/platform/qvantel-vault-secrets-webhook
    tag: 1.0.0.1_master_e5e0236d8
namespaceSelector:
    matchExpressions:
        - key: kubernetes.io/metadata.name
          operator: In
          values:
            - qvantel
            - platform
podsFailurePolicy: Fail
secretsFailurePolicy: Fail
secretsMutation: false
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters
vaultEnv:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/bank-vaults/vault-env</code></pre>
</td>
			<td><div>

Configuration for underlying vault-secrets-webhook helm-chart. See https://github.com/bank-vaults/vault-secrets-webhook/blob/main/deploy/charts/vault-secrets-webhook/README.md#values

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vault-secrets-webhook--configMapFailurePolicy">vaultPlatform.vault-secrets-webhook.configMapFailurePolicy</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>Fail</code></pre>
</td>
			<td><div>

This is important! If Vault is down (or sealed), then webhooks will fail and potentially block everything else in the cluster. "Ignore" is recommended with Vault without auto-unsealing.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vault-secrets-webhook--podsFailurePolicy">vaultPlatform.vault-secrets-webhook.podsFailurePolicy</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>Fail</code></pre>
</td>
			<td><div>

This is important! If Vault is down (or sealed), then webhooks will fail and potentially block everything else in the cluster. "Ignore" is recommended with Vault without auto-unsealing.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vault-secrets-webhook--secretsFailurePolicy">vaultPlatform.vault-secrets-webhook.secretsFailurePolicy</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>Fail</code></pre>
</td>
			<td><div>

This is important! If Vault is down (or sealed), then webhooks will fail and potentially block everything else in the cluster. "Ignore" is recommended with Vault without auto-unsealing.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync">vaultPlatform.vaultCrdSync</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>schedule: '*/5 * * * *'
syncAclPolicies:
    enabled: true
    namespaceSelector:
        nameSelector:
            matchNames:
                - platform
syncDbConnections:
    enabled: true
    namespaceSelector:
        nameSelector:
            matchNames:
                - platform
syncDbRoles:
    enabled: true
    namespaceSelector:
        nameSelector:
            matchNames:
                - platform
syncKV1Secrets:
    enabled: true
    namespaceSelector:
        nameSelector:
            matchNames:
                - qvantel
                - platform
syncKubernetesAuthRoles:
    enabled: true
    namespaceSelector:
        nameSelector:
            matchNames:
                - platform</code></pre>
</td>
			<td><div>

Configuration for Vault CRDs (DbConnection, DbRoles, etc) reconciliation.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--schedule">vaultPlatform.vaultCrdSync.schedule</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>'*/5 * * * *'</code></pre>
</td>
			<td><div>

Schedule for periodic reconciliation. Default is "*/5 * * * *" - so every 5 minutes.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncAclPolicies--enabled">vaultPlatform.vaultCrdSync.syncAclPolicies.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

Enables Vault CRDs reconciliation for ACL policies

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncAclPolicies--namespaceSelector">vaultPlatform.vaultCrdSync.syncAclPolicies.namespaceSelector</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - platform</code></pre>
</td>
			<td><div>

Selector for namespaces from which to sync Vault ACL Policy resources. Default is `platform` namespace.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncDbConnections--enabled">vaultPlatform.vaultCrdSync.syncDbConnections.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

Enables Vault CRDs reconciliation for DB connections

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncDbConnections--namespaceSelector">vaultPlatform.vaultCrdSync.syncDbConnections.namespaceSelector</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - platform</code></pre>
</td>
			<td><div>

Selector for namespaces from which to sync Vault DB connection resources. Default is `platform` namespace.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncDbRoles--enabled">vaultPlatform.vaultCrdSync.syncDbRoles.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

Enables Vault CRDs reconciliation for DB roles

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncDbRoles--namespaceSelector">vaultPlatform.vaultCrdSync.syncDbRoles.namespaceSelector</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - platform</code></pre>
</td>
			<td><div>

Selector for namespaces from which to sync Vault DB roles resources. Default is `platform` namespace.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncKV1Secrets--enabled">vaultPlatform.vaultCrdSync.syncKV1Secrets.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

Enables Vault CRDs reconciliation for KV1 Secrets

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncKV1Secrets--namespaceSelector">vaultPlatform.vaultCrdSync.syncKV1Secrets.namespaceSelector</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - qvantel
        - platform</code></pre>
</td>
			<td><div>

Selector for namespaces from which to sync Vault KV1 Secrets resources. Default are `qvantel` and `platform` namespaces.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncKubernetesAuthRoles--enabled">vaultPlatform.vaultCrdSync.syncKubernetesAuthRoles.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

Enables Vault CRDs reconciliation for KubernetesAuthRoles

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultCrdSync--syncKubernetesAuthRoles--namespaceSelector">vaultPlatform.vaultCrdSync.syncKubernetesAuthRoles.namespaceSelector</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - platform</code></pre>
</td>
			<td><div>

Selector for namespaces from which to sync Vault KubernetesAuthRole resources. Default is `platform` namespace.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--vaultWebhooksEnabled">vaultPlatform.vaultWebhooksEnabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
			<td><div>

Enable deployment of vault-secrets-webhook subchart. Depends of value of `global.clusterwideResources` flag

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="vaultPlatform--webhookCertificateDuration">vaultPlatform.webhookCertificateDuration</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>87600h</code></pre>
</td>
			<td><div>

Sets the validity duration in hours for the vault-webhook certificate, must be larger than renewaltime ( 360h = 15 days), default is 10 years

</div>
</td>
		</tr>
	</tbody>
</table>

