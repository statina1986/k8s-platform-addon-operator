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

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| vaultPlatform.autoUnseal | bool | `false` | Enable auto unseal with external Cloud secrets service (KMS). See https://developer.hashicorp.com/vault/docs/concepts/seal#auto-unseal |
| vaultPlatform.k8sUnseal | bool | `false` | Enable auto unseal with local Shamir keys stored in local K8S secret |
| vaultPlatform.useBackwardsCompatibilityService | bool | `true` | Creates `vault.{{.Release.Namespace}}.svc` which is expected by Qvantel apps |
| vaultPlatform.vault | object | `{"global":{"enabled":true},"injector":{"enabled":false},"server":{"affinity":"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"vault.name\" . }}\n          app.kubernetes.io/instance: \"{{ .Release.Name }}\"\n          component: server\n      topologyKey: kubernetes.io/hostname\n","extraContainers":[{"args":["/init-script/init.sh"],"command":["/bin/sh"],"env":[{"name":"VAULT_K8S_POD_NAME","valueFrom":{"fieldRef":{"apiVersion":"v1","fieldPath":"metadata.name"}}},{"name":"VAULT_K8S_NAMESPACE","valueFrom":{"fieldRef":{"apiVersion":"v1","fieldPath":"metadata.namespace"}}},{"name":"VAULT_INIT_NODE","value":"vault-platform-0"}],"image":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/platform/platform-k8s-tools-minimal:1.2.0_10_5193dbce5","imagePullPolicy":"IfNotPresent","name":"auto-init-and-unseal-sidecar","volumeMounts":[{"mountPath":"/init-script/","name":"userconfig-vault-auto-init-config"}]}],"extraVolumes":[{"defaultMode":511,"name":"vault-auto-init-config","type":"configMap"}],"ha":{"enabled":true,"limits":{"memory":"1Gi"},"raft":{"additionalConfig":"","config":"ui = true\n\nlistener \"tcp\" {\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n  tls_disable = \"true\"\n}\n\nstorage \"raft\" {\n  path = \"/vault/data\"\n    retry_join {\n    leader_api_addr = \"http://vault-platform-0.vault-platform-internal:8200\"\n  }\n  retry_join {\n    leader_api_addr = \"http://vault-platform-1.vault-platform-internal:8200\"\n  }\n  retry_join {\n    leader_api_addr = \"http://vault-platform-2.vault-platform-internal:8200\"\n  }\n\n  autopilot {\n    cleanup_dead_servers = \"true\"\n    last_contact_threshold = \"200ms\"\n    last_contact_failure_threshold = \"10m\"\n    max_trailing_logs = 250000\n    min_quorum = 5\n    server_stabilization_time = \"10s\"\n  }\n\n}\n\nservice_registration \"kubernetes\" {}\n{{ .Values.server.ha.raft.additionalConfig}}\n","enabled":true,"setNodeId":true},"replicas":3,"requests":{"cpu":"100m","memory":"100Mi"}},"image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/hashicorp/vault"},"livenessProbe":{"enabled":true,"initialDelaySeconds":60,"path":"/v1/sys/health?standbyok=true&sealedcode=204"},"readinessProbe":{"enabled":true,"path":"/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"},"resources":{},"serviceAccount":{"create":false,"name":"platform"},"tolerations":"- key: \"dedicated-nodes\"\n  value: \"platform-masters\"\n  operator: \"Equal\"\n  effect: \"NoSchedule\"\n"}}` | Configuration for underlying vault helm-chart. See https://developer.hashicorp.com/vault/docs/platform/k8s/helm/configuration |
| vaultPlatform.vault-secrets-webhook | object | `{"certificate":{"generate":false,"useCertManager":true},"configMapFailurePolicy":"Fail","image":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/platform/qvantel-vault-secrets-webhook","tag":"1.0.0.1_master_e5e0236d8"},"namespaceSelector":{"matchExpressions":[{"key":"kubernetes.io/metadata.name","operator":"In","values":["qvantel"]}]},"podsFailurePolicy":"Fail","secretsFailurePolicy":"Fail","tolerations":[{"effect":"NoSchedule","key":"dedicated-nodes","operator":"Equal","value":"platform-masters"}],"vaultEnv":{"repository":"platform.artifactory.qvantel.net/k8s-platform-1-2-0/bank-vaults/vault-env"}}` | Configuration for underlying vault-secrets-webhook helm-chart. See https://github.com/bank-vaults/vault-secrets-webhook/blob/main/deploy/charts/vault-secrets-webhook/README.md#values |
| vaultPlatform.vault-secrets-webhook.configMapFailurePolicy | string | `"Fail"` | This is important! If Vault is down (or sealed), then webhooks will fail and potentially block everything else in the cluster. "Ignore" is recommended with Vault without auto-unsealing. |
| vaultPlatform.vault-secrets-webhook.podsFailurePolicy | string | `"Fail"` | This is important! If Vault is down (or sealed), then webhooks will fail and potentially block everything else in the cluster. "Ignore" is recommended with Vault without auto-unsealing. |
| vaultPlatform.vault-secrets-webhook.secretsFailurePolicy | string | `"Fail"` | This is important! If Vault is down (or sealed), then webhooks will fail and potentially block everything else in the cluster. "Ignore" is recommended with Vault without auto-unsealing. |
| vaultPlatform.vaultWebhooksEnabled | bool | `true` | Enable deployment of vault-secrets-webhook subchart. Depends of value of `global.clusterwideResources` flag |