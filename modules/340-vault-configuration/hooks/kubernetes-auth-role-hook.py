#!/usr/bin/env python3

import sys
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.inline import *


class KubernetesAuthRoleHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
kubernetes:
- name: "Monitor Vault KubernetesAuthRoles"
  apiVersion: platform-vault.qvantel.com/v1
  kind: KubernetesAuthRole
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: KubernetesAuthRoleQueue
  allowFailure: true
  jqFilter: '.spec'
""")

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event):

                name = event['object']['metadata']['name']
                namespace = event['object']['metadata']['namespace']
                mount_point = event['object']['spec'].get(
                    'mount_point', 'kubernetes')
                
                vault_client = get_vault_client()

                if eventName == "Deleted":
                    vault_client.auth.kubernetes.delete_role(
                        name=name,
                        mount_point=mount_point)
                else:
                    try:
                        bound_service_account_names = event['object']['metadata']['bound_service_account_names']
                        bound_service_account_namespaces = event['object']['spec']['bound_service_account_namespaces']
                        token_policies = event['object']['spec']['token_policies']
                        additional_params = event['object']['spec'].get(
                            'additional-params', {})
                        token_ttl = event['object']['spec'].get('token_ttl', '0')
                        token_max_ttl = event['object']['spec'].get(
                            'token_max_ttl', '0')

                        vals = get_computed_values(computed_values)

                        bound_service_account_names = replace_computed_values(bound_service_account_names, vals)
                        bound_service_account_namespaces = replace_computed_values(
                            bound_service_account_namespaces, vals)
                        token_policies = replace_computed_values(
                            token_policies, vals)

                        vault_client.auth.kubernetes.create_role(
                            name=name,
                            bound_service_account_names=bound_service_account_names,
                            bound_service_account_namespaces=bound_service_account_namespaces,
                            ttl=token_ttl,
                            max_ttl=token_max_ttl,
                            policies=token_policies,
                            mount_point=mount_point
                            ** additional_params)

                        execute_post_actions(post_actions, vals)

                        update_crd_status(
                            group="platform-vault.qvantel.com",
                            version="v1",
                            name=name,
                            namespace=namespace,
                            plural="kubernetesauthroles",
                            update=lambda response: updateCrdStatusCondition(
                                    response, "Ready", "True", "KubernetesAuthRoleProvisioned")
                        )
                    except:
                        update_crd_status(
                            group="platform-vault.qvantel.com",
                            version="v1",
                            name=name,
                            namespace=namespace,
                            plural="kubernetesauthroles",
                            update=lambda response: updateCrdStatusCondition(
                                response, "Ready", "False", "KubernetesAuthRoleFailed", get_exception_string())
                        )
                        raise
            case _:
                print("Unknown hook data")


hook = KubernetesAuthRoleHook()
hook.handle_hook()