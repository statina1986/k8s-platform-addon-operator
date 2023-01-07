from os import environ
from kubernetes import client, config



def get_k8s_client():
    if environ.get('INSIDE_CLUSTER', 'false') == 'true':
        config.load_incluster_config()
    else:
        config.load_kube_config()
    k8s = client.CoreV1Api()
    return k8s