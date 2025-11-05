#!/usr/bin/env python3

import sys

from hvac import Client
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.inline import *


class RabbitMqConnectionHook(Hook):
    def __init__(self):
        vaultPlatform = self.get_addon_operator_config("vaultPlatform")
        platformNamespace = self.get_addon_operator_config('global').get('platformNamespace','platform')
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "rabbitmqconnections-periodic-checking",
                        "crontab": vaultPlatform.get("vaultCrdSync", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-vault-rabbitmqconnections"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-vault-rabbitmqconnections",
                        "apiVersion": "platform-vault.qvantel.com/v1",
                        "kind": "RabbitMqConnection",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "VaultRabbitMqConnectionQueue",
                        "namespace": vaultPlatform.get("vaultCrdSync", {}).get("syncRabbitMqConnections", {}).get("namespaceSelector", {
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

    def registerResource(self, event, vault_client: Client):
        try:
            name = event['object']['metadata']['name']
            namespace = event['object']['metadata']['namespace']
            additional_params = event['object']['spec'].get('additional-params', {})
            computed_values = event['object']['spec'].get('computed-values', {})
            post_actions = event['object']['spec'].get('post-actions', {})
            username = event['object']['spec'].get('username', '')
            password = event['object']['spec'].get('password', '')
            connection_url = event['object']['spec'].get('connection-url', '')

            vals = get_computed_values(computed_values)

            connection_url = replace_computed_values(connection_url, vals)
            username = replace_computed_values(username, vals)
            password = replace_computed_values(password, vals)

            vault_client.secrets.rabbitmq.configure(
                connection_uri=connection_url,
                username=username,
                password=password,
                **additional_params)

            execute_post_actions(post_actions, vals)

            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="rabbitmqconnections",
                update=lambda response: updateCrdStatusCondition(
                        response, "Ready", "True", "RabbitMQConnectionProvisioned")
            )
        except:
            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="rabbitmqconnections",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "False", "RabbitMQCConnectionFailed", get_exception_string())
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
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncRabbitMqConnections', {}).get('enabled') in ('false', False):
                    print("Skipping Vault RabbitMQC connections sync as it is disabled in configuration")
                    return
                
                vault_client = get_vault_client()

                if eventName == "Deleted":                    
                    return
                else:
                    self.registerResource(event, vault_client)

            case ScheduleHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncRabbitMqConnections', {}).get('enabled') in ('false', False):
                    print("Skipping Vault RabbitMQ connections sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('snapshots', {}).get('monitor-vault-rabbitmqconnections', []):
                    # Skipping 'Ready' resources from scheduled execution as those were already applied
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping RabbitMqConnection " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.registerResource(event, vault_client)

            case SynchronizationHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncRabbitMqConnections', {}).get('enabled') in ('false', False):
                    print("Skipping Vault RabbitMQ connections sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('objects', []):
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping RabbitMqConnection " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.registerResource(event, vault_client)
            case _:
                print("Unknown hook data")


hook = RabbitMqConnectionHook()
hook.handle_hook()
