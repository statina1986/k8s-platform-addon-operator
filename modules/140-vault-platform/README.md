# vault-platform module
This module is responsible for deployment of [vault](https://www.vaultproject.io/) in the cluster

Depends on modules:
- [cert-platform](/modules/110-cert-platform/README.md) which is needed to established vault certificates

### Auto initialization
Module is deployed with auto-initialization feature whichis capable to aut-initialize **vault**.
If auto-useal deature is not used, Shamir keys will be stored in k8s secret.

### Auto-unsealing
It is possible to configure module to use auto-unsealing feature with external secrets service:
* AWS KMS. In this case following is needed:  
  * Service Account should be annotated with IAM role which has needed KMS permissions (e.g. : eks.amazonaws.com/role-arn: arn:aws:iam::386844351831:role/eksctl-platform-gitops-sit-addon-iamservicea-Role1-M314GVKTRB5M)
  * **vault** config should contain auto-unseal block containing KMS key id
    ```
    seal "awskms" {
        region     = "eu-central-1"
        kms_key_id = "arn:aws:kms:eu-central-1:386844351831:key/mrk-a123090215d7415ab37eb27d76f4f35d"
    }
    ```