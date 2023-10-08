# cert-platform module
This module is responsible for deployment of [cert-manager](https://cert-manager.io/docs/) in the cluster and configuration of required platform certificates

Depends on modules:
- no dependencies

# qvantel.systems certificates

The qvantel.systems certificate is created using the clusterIssuer and certificate definitions found in templates. The required AWS configurations need to be done using this documentation https://cert-manager.io/docs/configuration/acme/dns01/route53/ and below you can find the examples to Qvantel specific deployments.

# AWS IT configurations

Our configuration is done with the Route 53 and that requires a role that has the rights to access the required services. Below you can find the role example that is required for the platform mumbai environment.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::386844351831:role/qv-mumbai-platform-1-certmanager"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
```
The forementioned role requires a access policy that allows it to access the Route 53 and here we need to make sure that the hostedzone is pointing to the correct route53 resource. The example below is pointed towards the qvante.systems domain.

```json
{
    "Statement": [
        {
            "Action": "route53:GetChange",
            "Effect": "Allow",
            "Resource": "arn:aws:route53:::change/*"
        },
        {
            "Action": [
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:route53:::hostedzone/ZJ7W7ERY57J33"
        },
        {
            "Action": "route53:ListHostedZonesByName",
            "Effect": "Allow",
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
```

These configurations allow the cert-manager in AWS Development to manage Route 53 DNS zones in AWS IT.

# AWS Development configurations

The cert-manager pods running in our cluster require a credentials source in order to connect to the Route 53. The following policy was used in our mumbai platform cluster.

```json
{
    "Statement": [
        {
            "Action": [
                "sts:AssumeRole"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:iam::067412573140:role/qv-mumbai-platform-1-dns-manager"
        }
    ],
    "Version": "2012-10-17"
}
```

The cert-manager role requires the following trust releationship in order to use the IRSA method. More information on everything that needs to be changed can be found on the official documentation that was linked before.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::386844351831:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/4C1BD9CECF5F6A3152F0ED938E8A21AA"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.ap-south-1.amazonaws.com/id/4C1BD9CECF5F6A3152F0ED938E8A21AA:sub": "system:serviceaccount:platform:cert-platform-cert-manager"
                }
            }
        }
    ]
}
```

# Addon-operator configurations

After these steps are done the created role needs to be added to the service account as a annotation. The file system permissions also need to be updated so that the ServiceAccount token can be read. Example configuration of this can be found below.

```markdown
cert-manager:
    serviceAccount:
    annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::386844351831:role/qv-mumbai-platform-1-certmanager"
    securityContext:
    fsGroup: 1001
```