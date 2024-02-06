# vault-platform module
This module is responsible for deployment of [vault](https://www.vaultproject.io/) in the cluster

Depends on modules:
- [cert-platform](/modules/110-cert-platform/README.md) which is needed to established vault certificates

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
If auto-unseal feature is not used, Shamir keys will be stored in k8s secret.

### Auto-unsealing
It is possible to configure module to use auto-unsealing feature with external secrets service:
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

### Manage vault entities with CRDs
Provides configuration of following Vault entities via CRDs:
- [Kubernetes auth method role](./resources/kubernetes-auth-role.yaml)
- [Database secret engine connection](./resources/db-connection.yaml)
- [Database secret engine role](./resources/db-role.yaml)
- [ACL policy](./resources/acl-policy.yaml)
- [K/V Secrets(v1)](./resources/kv1-secret.yaml)

For details of each resource please check CRD definition.