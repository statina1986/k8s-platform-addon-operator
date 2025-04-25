#!/usr/bin/env python3

import sys
from kubernetes import client, config
from common.python.hooks import *
from common.python.inline import *
from common.python.utils import get_exception_string
from common.python.vault import *
import hvac

config.load_incluster_config()
v1 = client.CoreV1Api()


class AclPoliciesHook(Hook):
    def __init__(self):
        vaultPlatform = self.get_addon_operator_config("vaultPlatform")        
        platformNamespace = self.get_addon_operator_config('global').get('platformNamespace','platform')
        appsNamespace = self.get_addon_operator_config('global').get('appsNamespace','qvantel')
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "aclpolicy-periodic-checking",
                        "crontab": vaultPlatform.get("vaultCrdSync", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-vault-aclpolicy"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-vault-aclpolicy",
                        "apiVersion": "platform-vault.qvantel.com/v1",
                        "kind": "AclPolicy",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "VaultAclPolicyQueue",
                        "namespace": vaultPlatform.get("vaultCrdSync", {}).get("syncAclPolicies", {}).get("namespaceSelector", {
                            "nameSelector": {
                                "matchNames": [ appsNamespace, platformNamespace ]
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
            policy_name = event.get('object', {}).get('spec', {}).get('policy-name', name)
            policy_hcl = event['object']['spec']['policy-hcl']

            computed_values = event['object']['spec'].get('computed-values', {})
            post_actions = event['object']['spec'].get('post-actions', {})

            vals = get_computed_values(computed_values)

            policy_name = replace_computed_values(policy_name, vals)
            policy_hcl = replace_computed_values(policy_hcl, vals)

            vault_client.sys.create_or_update_policy(name=policy_name, policy=policy_hcl)

            execute_post_actions(post_actions, vals)

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

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncAclPolicies', {}).get('enabled') in ('false', False):
                    print("Skipping Vault ACL Policies sync as it is disabled in configuration")
                    return

                name = event['object']['metadata']['name']
                policy_name = event.get('object', {}).get('spec', {}).get('policy-name', name)

                vault_client = get_vault_client()

                if eventName == "Deleted":
                    vault_client.sys.delete_policy(name=policy_name)
                    return
                else:
                    self.registerResource(event, vault_client)

            case ScheduleHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncAclPolicies', {}).get('enabled') in ('false', False):
                    print("Skipping Vault ACL Policies sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('snapshots', {}).get('monitor-vault-aclpolicy', []):
                    self.registerResource(event, vault_client)

            case SynchronizationHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncAclPolicies', {}).get('enabled') in ('false', False):
                    print("Skipping Vault ACL Policies sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('objects', []):
                    self.registerResource(event, vault_client)
            case _:
                print("Unknown hook data")


hook = AclPoliciesHook()
hook.handle_hook()
