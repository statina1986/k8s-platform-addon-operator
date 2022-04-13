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
- name: "Monitor Vault AclPolicy"
  kind: AclPolicy  
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: AclPolicyQueue
""")
    case EventHook(eventName, context):
        policy_name = context[0]['object']['metadata']['name']

        secret = v1.read_namespaced_secret("vault-keys", "platform").data
        token = base64.b64decode(secret["root_token"]).decode('utf-8')
        vault_client = hvac.Client(
            url='http://vault-platform.platform.svc.cluster.local:8200', token=token)

        if eventName == "Deleted":
            vault_client.sys.delete_policy(name=policy_name)
        else:
            policy_hcl = context[0]['object']['spec']['policy-hcl']
            vault_client.sys.create_or_update_policy(
                name=policy_name, policy=policy_hcl)
    case _:
        print("Unknown hook data")
