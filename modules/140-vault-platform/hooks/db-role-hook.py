#!/usr/bin/env python3

import sys
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.inline import *


class DbRoleHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
kubernetes:
- name: "Monitor Vault DbRoles"
  apiVersion: platform-vault.qvantel.com/v1
  kind: DbRole
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: DbRoleQueue
  allowFailure: true
  jqFilter: '.spec'
""")

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event):

                name = event['object']['metadata']['name']
                namespace = event['object']['metadata']['namespace']
                mount_point = event['object']['spec'].get(
                    'mount-point', 'database')
                role_name = event['object']['spec'].get('role-name', name)

                vault_client = get_vault_client()

                if eventName == "Deleted":
                    vault_client.secrets.database.delete_role(
                        name=role_name,
                        mount_point=mount_point)
                    return
                else:
                    try:
                        db_name = event['object']['spec']['db-name']
                        creation_statements = event['object']['spec']['creation-statements']
                        additional_params = event['object']['spec'].get(
                            'additional-params', {})
                        max_ttl = event['object']['spec'].get('max-ttl', '0')
                        default_ttl = event['object']['spec'].get(
                            'default-ttl', '0')
                        computed_values = event['object']['spec'].get(
                            'computed-values', {})
                        post_actions = event['object']['spec'].get(
                            'post-actions', {})

                        vals = get_computed_values(computed_values)

                        db_name = replace_computed_values(db_name, vals)
                        role_name = replace_computed_values(role_name, vals)
                        max_ttl = replace_computed_values(
                            max_ttl, vals)
                        default_ttl = replace_computed_values(
                            default_ttl, vals)
                        creation_statements = replace_computed_values(
                            creation_statements, vals)

                        vault_client.secrets.database.create_role(
                            name=role_name,
                            db_name=db_name,
                            creation_statements=creation_statements,
                            default_ttl=default_ttl,
                            max_ttl=max_ttl,
                            mount_point=mount_point,
                            ** additional_params)

                        execute_post_actions(post_actions, vals)

                        update_crd_status(
                            group="platform-vault.qvantel.com",
                            version="v1",
                            name=name,
                            namespace=namespace,
                            plural="dbroles",
                            update=lambda response: updateCrdStatusCondition(
                                    response, "Ready", "True", "DbRoleProvisioned")
                        )
                    except:
                        update_crd_status(
                            group="platform-vault.qvantel.com",
                            version="v1",
                            name=name,
                            namespace=namespace,
                            plural="dbroles",
                            update=lambda response: updateCrdStatusCondition(
                                response, "Ready", "False", "DbRoleFailed", get_exception_string())
                        )
                        raise
            case _:
                print("Unknown hook data")


hook = DbRoleHook()
hook.handle_hook()
