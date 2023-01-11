import base64
import hvac
from common.python.variables import *
from common.python.k8s import *

vault_client = None

def get_vault_client():
    global vault_client
    if vault_client is None:    
        secret = get_k8s_client().read_namespaced_secret(VAULT_SECRET_NAME, VAULT_SECRET_NAMESPACE).data
        token = base64.b64decode(secret[VAULT_SECRET_ROOT_TOKEN]).decode('utf-8')
        vault_client = hvac.Client(url=VAULT_ADDR, token=token)
    return vault_client