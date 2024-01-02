# vault-configuration module
This module is responsible for configuration of [vault](https://www.vaultproject.io/) deployment

Depends on modules:
- [vault-platform](../140-vault-platform/README.md) which deploys vault

Provides configuration of following Vault entities via CRDs:
- [Kubernetes auth method role](./resources/kubernetes-auth-role.yaml)
- [Database secret engine role](./resources/db-role.yaml)
- [ACL policy](./resources/acl-policy.yaml)

For details of each resource please check CRD definition.