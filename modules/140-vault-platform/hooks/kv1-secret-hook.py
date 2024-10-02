#!/usr/bin/env python3

import sys
from kubernetes import client, config
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.variables import *
import hvac

config.load_incluster_config()
v1 = client.CoreV1Api()


class Kv1SecretsHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
kubernetes:
- name: "Monitor Vault KV1Secret"
  kind: KV1Secret  
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: KV1SecretQueue
  allowFailure: true
  jqFilter: '.spec'
""")

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, context):
                name = context['object']['metadata']['name']
                namespace = context['object']['metadata']['namespace']
                try:
                    path = context['object']['spec']['path']
                    # compatibility with qdeployer 3.80.0
                    if path.startswith("secret/"):
                        path = path.replace("secret/", "", 1)

                    secret = v1.read_namespaced_secret(
                        VAULT_SECRET_NAME, VAULT_SECRET_NAMESPACE).data
                    token = base64.b64decode(
                        secret["root_token"]).decode('utf-8')
                    vault_client = hvac.Client(
                        url=VAULT_ADDR, token=token)

                    if eventName == "Deleted":
                        # vault_client.secrets.kv.v1.delete_secret(path)
                        return
                    else:
                        values = context['object']['spec']['secret']
                        # Merge data from CRD with existing values. Existing values takes priority.
                        try:
                            existing = vault_client.secrets.kv.v1.read_secret(
                                path)['data']
                            values = {**values, **existing}
                        except:
                            pass
                        vault_client.secrets.kv.v1.create_or_update_secret(
                            path, secret=values)

                    update_crd_status(
                        group="platform-vault.qvantel.com",
                        version="v1",
                        name=name,
                        namespace=namespace,
                        plural="kv1secrets",
                        update=lambda response: updateCrdStatusCondition(
                            response, "Ready", "True", "KV1SecretProvisioned")
                    )
                except:
                    update_crd_status(
                        group="platform-vault.qvantel.com",
                        version="v1",
                        name=name,
                        namespace=namespace,
                        plural="kv1secrets",
                        update=lambda response: updateCrdStatusCondition(
                            response, "Ready", "False", "KV1SecretFailed", get_exception_string())
                    )
                    raise
            case _:
                print("Unknown hook data")


hook = Kv1SecretsHook()
hook.handle_hook()
