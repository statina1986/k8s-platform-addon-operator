#!/usr/bin/env python3

import sys
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.inline import *


class DbConnectionHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
kubernetes:
- name: "Monitor Vault DbConnections"
  apiVersion: platform-vault.qvantel.com/v1
  kind: DbConnection
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: DbConnectionQueue
  allowFailure: true
  jqFilter: '.spec'
""")

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event):
                name = event['object']['metadata']['name']
                connection_name = event['object']['spec']['connection-name']
                namespace = event['object']['metadata']['namespace']
                vault_client = get_vault_client()

                if eventName == "Deleted":
                    vault_client.secrets.database.delete_connection(
                        connection_name)
                else:
                    try:
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
            case _:
                print("Unknown hook data")


hook = DbConnectionHook()
hook.handle_hook()
