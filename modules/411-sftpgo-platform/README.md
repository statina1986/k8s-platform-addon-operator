
# sftpgo

This module is responsible for deployment of [sftpgo](https://github.com/drakkan/sftpgo) in the cluster and the helm chart was community made, which can be found in [Github](https://github.com/sagikazarmark/helm-charts/tree/master/charts/sftpgo).

Depends on modules:
- no dependencies

The configuration requirements need a role to access the S3 bucket, which needs to be linked to the service account. Example of this can be found below

`"serviceAccount:
  # -- Enable service account creation.
  create: true

  # -- Annotations to be added to the service account.
  annotations:
    eks.amazonaws.com/role-arn: ${ARN}

  # -- The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template.
  name: "`