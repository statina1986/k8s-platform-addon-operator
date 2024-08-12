from os import environ

ADDON_OPERATOR_NAMESPACE = environ.get('ADDON_OPERATOR_NAMESPACE', 'platform')
ADDON_OPERATOR_CONFIG_MAP = environ.get('ADDON_OPERATOR_CONFIG_MAP', 'addon-operator')

VAULT_ADDR = environ.get('VAULT_ADDR', 'http://vault-platform.' + ADDON_OPERATOR_NAMESPACE + '.svc.cluster.local:8200')
VAULT_SECRET_NAME = environ.get('VAULT_SECRET_NAME', 'vault-keys')
VAULT_SECRET_NAMESPACE = environ.get('VAULT_SECRET_NAMESPACE', 'platform')
VAULT_SECRET_ROOT_TOKEN = environ.get('VAULT_SECRET_ROOT_TOKEN', 'root_token')
