from os import environ
from kubernetes import client, config

if environ.get('INSIDE_CLUSTER', 'false') == 'true':
    config.load_incluster_config()
else:
    config.load_kube_config()
k8s = client.CoreV1Api()