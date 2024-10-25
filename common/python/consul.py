import consul
from common.python.variables import *
from common.python.k8s import *

consul_client = None


def get_consul_client():
    global consul_client
    if consul_client is None:
        consul_client = consul.Consul(host=CONSUL_HOST, port=CONSUL_PORT, scheme=CONSUL_SCHEME)
    return consul_client
