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


class AclPoliciesHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
kubernetes:
- name: "Monitor Vault AclPolicy"
  kind: AclPolicy
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: AclPolicyQueue
  allowFailure: true
  jqFilter: '.spec'
""")

    def handle_binding(self, binding):
            match(binding):
                case EventHook(eventName, context):
                    name = context['object']['metadata']['name']  
                    namespace = context['object']['metadata']['namespace']
                    try:
                        policy_name = context.get('object', {}).get(
                            'spec', {}).get('policy-name')

                        secret = v1.read_namespaced_secret(
                            VAULT_SECRET_NAME, VAULT_SECRET_NAMESPACE).data
                        token = base64.b64decode(secret["root_token"]).decode('utf-8')
                        vault_client = hvac.Client(
                            url=VAULT_ADDR, token=token)

                        if eventName == "Deleted":
                            vault_client.sys.delete_policy(name=(policy_name or name))
                            return
                        else:
                            policy_hcl = context['object']['spec']['policy-hcl']
                            vault_client.sys.create_or_update_policy(
                                name=(policy_name or name), policy=policy_hcl)

                        update_crd_status(
                                group="platform-vault.qvantel.com",
                                version="v1",
                                name=name,
                                namespace=namespace,
                                plural="aclpolicies",
                                update=lambda response: updateCrdStatusCondition(
                                    response, "Ready", "True", "AclPolicyProvisioned")
                            )
                    except:
                        update_crd_status(
                            group="platform-vault.qvantel.com",
                            version="v1",
                            name=name,
                            namespace=namespace,
                            plural="aclpolicies",
                            update=lambda response: updateCrdStatusCondition(
                                response, "Ready", "False", "AclPolicyFailed", get_exception_string())
                        )
                        raise
                case _:
                    print("Unknown hook data")


hook = AclPoliciesHook()
hook.handle_hook()
