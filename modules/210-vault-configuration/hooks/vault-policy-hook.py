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
{
  "configVersion":"v1",
  "kubernetes":[{
    "name": "Monitor Vault Policies",
    "kind": "VaultPolicy",
    "executeHookOnEvent":["Added","Modified","Deleted"]
  }]
}
""")
    case EventHook(eventName, context):
        policy_name = context[0]['object']['spec']['policy-name']

        secret = v1.read_namespaced_secret("vault-dev-keys", "platform").data
        token = base64.b64decode(
            secret["vault-dev-root-token"]).decode('utf-8')
        vault_client = hvac.Client(
            url='http://vault.platform.svc.cluster.local:8200', token=token)

        if eventName == "Deleted":
            # exec_vault_command(v1, "vault policy delete " + policy_name)
            vault_client.sys.delete_policy(name=policy_name)
        else:
            policy_hcl = context[0]['object']['spec']['policy-hcl']
            vault_client.sys.create_or_update_policy(
                name=policy_name, policy=policy_hcl)
            # exec_vault_command(v1, "vault policy write " +
            #                    policy_name + ' - ' + policy_hcl)
    case _:
        print("Unknown hook data")
