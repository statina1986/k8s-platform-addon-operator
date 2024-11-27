#!/usr/bin/env python3

import sys
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.inline import *


class KubernetesAuthRoleHook(Hook):
    def __init__(self):
        vaultPlatform = self.get_addon_operator_config("vaultPlatform")
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "kubernetesauthroles-periodic-checking",
                        "crontab": vaultPlatform.get("vaultCrdSync", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-vault-kubernetesauthroles"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-vault-kubernetesauthroles",
                        "apiVersion": "platform-vault.qvantel.com/v1",
                        "kind": "KubernetesAuthRole",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "VaultKubernetesAuthRoleQueue",
                        "namespace": vaultPlatform.get("vaultCrdSync", {}).get("namespaceSelector", {
                            "labelSelector": {
                                "matchLabels": {
                                    "platform.qvantel.com/vault-"+ADDON_OPERATOR_NAMESPACE+"-crd-sync": "true"
                                }
                            }
                        }),
                        "allowFailure": True,
                        "jqFilter": '.spec'
                    }
                ]
            })
        )

    def registerResource(self, event, vault_client):
        try:
            name = event['object']['metadata']['name']
            namespace = event['object']['metadata']['namespace']
            mount_point = event['object']['spec'].get('mount_point', 'kubernetes')

            bound_service_account_names = event['object']['spec']['bound_service_account_names']
            bound_service_account_namespaces = event['object']['spec']['bound_service_account_namespaces']
            token_policies = event['object']['spec']['token_policies']
            additional_params = event['object']['spec'].get('additional-params', {})
            token_ttl = event['object']['spec'].get('token_ttl', '0')
            token_max_ttl = event['object']['spec'].get('token_max_ttl', '0')
            computed_values = event['object']['spec'].get('computed-values', {})
            post_actions = event['object']['spec'].get('post-actions', {})

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
                mount_point=mount_point,
                ** additional_params)

            execute_post_actions(post_actions, vals)

            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="kubernetesauthroles",
                update=lambda response: updateCrdStatusCondition(response, "Ready", "True", "KubernetesAuthRoleProvisioned")
            )
        except:
            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="kubernetesauthroles",
                update=lambda response: updateCrdStatusCondition(response, "Ready", "False", "KubernetesAuthRoleFailed", get_exception_string())
            )
            raise

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event):

                name = event['object']['metadata']['name']
                mount_point = event['object']['spec'].get('mount_point', 'kubernetes')

                vault_client = get_vault_client()

                if eventName == "Deleted":
                    vault_client.auth.kubernetes.delete_role(name=name, mount_point=mount_point)
                    return
                else:
                    self.registerResource(event, vault_client)

            case ScheduleHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping Vault CRD sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('snapshots', {}).get('monitor-vault-kubernetesauthroles', []):
                    self.registerResource(event, vault_client)

            case SynchronizationHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping Vault CRD sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('objects', []):
                    self.registerResource(event, vault_client)
            case _:
                print("Unknown hook data")

hook = KubernetesAuthRoleHook()
hook.handle_hook()
