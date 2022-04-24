#!/usr/bin/env python3

import sys
from kubernetes import client, config
from common.python.hooks import *
from common.python.vault import *
import hvac

config.load_incluster_config()
v1 = client.CoreV1Api()

match(handle_hook()):
    case ConfigHook():
        print(
            """
configVersion: v1
kubernetes:
- name: "Monitor Vault KV1Secret"
  kind: KV1Secret  
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: KV1SecretQueue
""")
    case EventHook(eventName, context):
        for val in context:
            name = val['object']['metadata']['name']
            eventName = val['watchEvent']
            path = val['object']['spec']['path'] 

            secret = v1.read_namespaced_secret("vault-keys", "platform").data
            token = base64.b64decode(secret["root_token"]).decode('utf-8')
            vault_client = hvac.Client(
                url='http://vault-platform.platform.svc.cluster.local:8200', token=token)

            if eventName == "Deleted":
                vault_client.secrets.kv.v1.delete_secret(path)
            else:                
                values = val['object']['spec']['secret']
                vault_client.secrets.kv.v1.create_or_update_secret(path, secret=values)
    case _:
        print("Unknown hook data")
