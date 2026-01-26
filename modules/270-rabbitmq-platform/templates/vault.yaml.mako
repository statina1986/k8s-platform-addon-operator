% if addon_operator['vaultPlatformEnabled'] == 'true':
### Vault DB Connection
---
apiVersion: platform-vault.qvantel.com/v1
kind: RabbitMqConnection
metadata:
  annotations:
    platform.qvantel.com/retry-count: "100"
  name: {{ $.Values.global.helmReleaseNamePrefix }}rabbitmq-platform-vault-connection
spec:
  connection-url: "http://{{ $.Values.global.helmReleaseNamePrefix }}rabbitmq-platform.{{ $.Release.Namespace }}.svc:15672"
  computed-values:
  - expression: k8s_get_secret_value('{{ $.Values.global.helmReleaseNamePrefix }}rabbitmq-platform','{{ $.Release.Namespace }}','rabbitmq-password')
    name: secret-password
  username: '{{ $.Values.rabbitmqPlatform.rabbitmq.auth.username }}'
  password: '{secret-password}'
% endif