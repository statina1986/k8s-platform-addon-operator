from os import environ

VAULT_ADDR=environ.get('VAULT_ADDR', 'http://vault-platform.platform.svc.cluster.local:8200')
VAULT_SECRET_NAME=environ.get('VAULT_SECRET_NAME', 'vault-keys')
VAULT_SECRET_NAMESPACE=environ.get('VAULT_SECRET_NAMESPACE', 'platform')
VAULT_SECRET_ROOT_TOKEN=environ.get('VAULT_SECRET_ROOT_TOKEN', 'root_token')
