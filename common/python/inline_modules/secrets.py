import boto3
from common.python.vault import *
from common.python.k8s import *
from kubernetes.client.rest import ApiException

# SECRETS MANAGEMENT FUNCTIONS

def aws_get_secret_value(secretId):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secretId)
    return response


def k8s_get_secret_value(secretName, secretNamespace, key):
    k8s = get_k8s_client()
    secret = k8s.read_namespaced_secret(secretName, secretNamespace).data
    value = base64.b64decode(secret[key]).decode('utf-8')
    return value


def k8s_store_secret_value(secretName, secretNamespace, key, value):
    k8s = get_k8s_client()
    try:
        secret = client.V1Secret(metadata=client.V1ObjectMeta(name=secretName))
        k8s.create_namespaced_secret(namespace=secretNamespace, body=secret)
    except client.rest.ApiException as e:
        if e.status == 409:
            logger.info("Secret already exist")
        else:
            raise e
    patch = {
        "data": {}
    }
    patch['data'][key] = base64.b64encode(value.encode('utf-8')).decode("utf-8")
    k8s.patch_namespaced_secret(secretName, secretNamespace, patch)
    return value


def vault_store_secret(path, key, value):
    vault_client = get_vault_client()
    try:
        existing = vault_client.secrets.kv.v1.read_secret(path)['data']
    except:
        existing = {}

    existing[key] = value
    vault_client.secrets.kv.v1.create_or_update_secret(path, existing)
    return value