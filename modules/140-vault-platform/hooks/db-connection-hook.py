#!/usr/bin/env python3

import sys
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.inline import *


class DbConnectionHook(Hook):
    def __init__(self):
        vaultPlatform = self.get_addon_operator_config("vaultPlatform")
        platformNamespace = self.get_addon_operator_config('global').get('platformNamespace','platform')
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "dbconnections-periodic-checking",
                        "crontab": vaultPlatform.get("vaultCrdSync", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-vault-dbconnections"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-vault-dbconnections",
                        "apiVersion": "platform-vault.qvantel.com/v1",
                        "kind": "DbConnection",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "VaultDbConnectionQueue",
                        "namespace": vaultPlatform.get("vaultCrdSync", {}).get("syncDbConnections", {}).get("namespaceSelector", {
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
            name = event['object']['metadata']['name']
            connection_name = event['object']['spec']['connection-name']
            namespace = event['object']['metadata']['namespace']
            plugin_name = event['object']['spec']['plugin-name']
            allowed_roles = event['object']['spec']['allowed-roles']
            additional_params = event['object']['spec'].get(
                'additional-params', {})
            computed_values = event['object']['spec'].get(
                'computed-values', {})
            post_actions = event['object']['spec'].get(
                'post-actions', {})
            db_username = event['object']['spec'].get(
                'db-username', '')
            db_password = event['object']['spec'].get(
                'db-password', '')
            db_url = event['object']['spec'].get(
                'db-url', '')

            vals = get_computed_values(computed_values)

            db_url = replace_computed_values(db_url, vals)
            db_username = replace_computed_values(
                db_username, vals)
            db_password = replace_computed_values(
                db_password, vals)

            vault_client.secrets.database.configure(
                name=connection_name,
                plugin_name=plugin_name,
                allowed_roles=allowed_roles,
                connection_url=db_url,
                username=db_username,
                password=db_password,
                **additional_params)

            execute_post_actions(post_actions, vals)

            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="dbconnections",
                update=lambda response: updateCrdStatusCondition(
                        response, "Ready", "True", "DbConnectionProvisioned")
            )
        except:
            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="dbconnections",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "False", "DbConnectionFailed", get_exception_string())
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
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncDbConnections', {}).get('enabled') in ('false', False):
                    print("Skipping Vault DB connections sync as it is disabled in configuration")
                    return

                name = event['object']['metadata']['name']
                connection_name = event['object']['spec']['connection-name']
                namespace = event['object']['metadata']['namespace']
                
                vault_client = get_vault_client()

                if eventName == "Deleted":
                    vault_client.secrets.database.delete_connection(
                        connection_name)
                    return
                else:
                    self.registerResource(event, vault_client)

            case ScheduleHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncDbConnections', {}).get('enabled') in ('false', False):
                    print("Skipping Vault DB connections sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('snapshots', {}).get('monitor-vault-dbconnections', []):
                    # Skipping 'Ready' resources from scheduled execution as those were already applied
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping DbConnection " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.registerResource(event, vault_client)

            case SynchronizationHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncDbConnections', {}).get('enabled') in ('false', False):
                    print("Skipping Vault DB connections sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('objects', []):
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping DbConnection " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.registerResource(event, vault_client)
            case _:
                print("Unknown hook data")


hook = DbConnectionHook()
hook.handle_hook()
