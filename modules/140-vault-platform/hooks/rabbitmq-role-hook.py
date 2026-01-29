#!/usr/bin/env python3

import sys
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.inline import *


class RabbitMqRoleHook(Hook):
    def __init__(self):
        vaultPlatform = self.get_addon_operator_config("vaultPlatform")
        platformNamespace = self.get_addon_operator_config('global').get('platformNamespace','platform')
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "rabbitmqroles-periodic-checking",
                        "crontab": vaultPlatform.get("vaultCrdSync", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-vault-rabbitmqroles"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-vault-rabbitmqroles",
                        "apiVersion": "platform-vault.qvantel.com/v1",
                        "kind": "RabbitMqRole",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "VaultRabbitMqRoleQueue",
                        "namespace": vaultPlatform.get("vaultCrdSync", {}).get("syncRabbitMqRoles", {}).get("namespaceSelector", {
                            "nameSelector": {
                                "matchNames": [ platformNamespace ]
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
            vhosts = event['object']['spec'].get('vhosts', "")
            vhost_topics = event['object']['spec'].get('vhost-topics', "")
            tags = event['object']['spec'].get('tags', "")
            additional_params = event['object']['spec'].get('additional-params', {})            
            computed_values = event['object']['spec'].get('computed-values', {})
            post_actions = event['object']['spec'].get('post-actions', {})
            mount_point = event['object']['spec'].get('mount-point', 'rabbitmq')
            name = event['object']['metadata']['name']
            namespace = event['object']['metadata']['namespace']
            role_name = event['object']['spec'].get('role-name', name)

            vals = get_computed_values(computed_values)

            role_name = replace_computed_values(role_name, vals)
            vhosts = replace_computed_values(vhosts, vals)
            vhost_topics = replace_computed_values(vhost_topics, vals)
            tags = replace_computed_values(tags, vals)

            vault_client.secrets.rabbitmq.create_role(
                name=role_name,
                vhosts=vhosts,
                vhost_topics=vhost_topics,
                tags=tags,
                mount_point=mount_point,
                ** additional_params)

            execute_post_actions(post_actions, vals)

            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="rabbitmqroles",
                update=lambda response: updateCrdStatusCondition(
                        response, "Ready", "True", "RabbitMqRoleProvisioned")
            )
        except:
            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="rabbitmqroles",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "False", "RabbitMqRoleFailed", get_exception_string())
            )
            raise

    def checkIfReady(self, event):
        conditions = event['object'].get('status', {}).get('conditions', [])
        for idx, item in enumerate(conditions):
            if ((item["type"] == "Ready") and (item["status"] == "True")):
                return True
        return False

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncRabbitMqRoles', {}).get('enabled') in ('false', False):
                    print("Skipping RabbitMQ DB roles sync as it is disabled in configuration")
                    return

                name = event['object']['metadata']['name']
                mount_point = event['object']['spec'].get('mount-point', 'rabbitmq')
                role_name = event['object']['spec'].get('role-name', name)

                vault_client = get_vault_client()

                if eventName == "Deleted":
                    vault_client.secrets.rabbitmq.delete_role(
                        name=role_name,
                        mount_point=mount_point)
                    return
                else:
                    self.registerResource(event, vault_client)
                    
            case ScheduleHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncRabbitMqRoles', {}).get('enabled') in ('false', False):
                    print("Skipping RabbitMQ DB roles sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('snapshots', {}).get('monitor-vault-rabbitmqroles', []):
                    # Skipping 'Ready' resources from scheduled execution as those were already applied
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping RabbitMqRole " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.registerResource(event, vault_client)

            case SynchronizationHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncRabbitMqRoles', {}).get('enabled') in ('false', False):
                    print("Skipping RabbitMQ DB roles sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('objects', []):
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping RabbitMqRole " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.registerResource(event, vault_client)
            case _:
                print("Unknown hook data")


hook = RabbitMqRoleHook()
hook.handle_hook()
