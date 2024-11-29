#!/usr/bin/env python3

import sys
from common.python.utils import *
from common.python.hooks import *
from common.python.vault import *
from common.python.k8s import *
from common.python.inline import *


class SqlInstallersHook(Hook):
    def __init__(self):
        qvantelGlue = self.get_addon_operator_config("qvantelGlue")
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "sql-installers-periodic-checking",
                        "crontab": qvantelGlue.get("sqlinstallersCrdSync", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-sql-installers"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-sql-installers",
                        "apiVersion": "platform.qvantel.com/v1",
                        "kind": "SqlInstallers",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "SqlInstallersQueue",
                        "namespace": qvantelGlue.get("sqlinstallersCrdSync", {}).get("namespaceSelector", {
                            "labelSelector": {
                                "matchLabels": {
                                    "platform.qvantel.com/vault-crd-sync": "true"
                                }
                            }
                        }),
                        "allowFailure": True,
                        "jqFilter": '.spec'
                    }
                ]
            })
        )

    def executeSql(self, event, k8s):
        try:
            name = event['object']['metadata']['name']
            db_provision_sql = event['object']['spec']['db-provision-sql']
            db_secret = event['object']['spec'].get(
                'db-secret-name', '')
            db_username = event['object']['spec'].get(
                'db-username', '')
            db_password = event['object']['spec'].get(
                'db-password', '')
            db_url = event['object']['spec']['db-url']
            db_type = event['object']['spec']['type']
            computed_values = event['object']['spec'].get(
                'computed-values', {})
            post_actions = event['object']['spec'].get(
                'post-actions', {})

            vals = get_computed_values(computed_values)

            db_url = replace_computed_values(db_url, vals)

            if db_secret != '':
                secret = k8s.read_namespaced_secret(
                    db_secret, 'platform').data
                db_username = base64.b64decode(
                    secret['username']).decode('utf-8')
                db_password = base64.b64decode(
                    secret['password']).decode('utf-8')

            db_username = replace_computed_values(
                db_username, vals)
            db_password = replace_computed_values(
                db_password, vals)

            if db_type == "mariadb":
                from MySQLdb import _mysql
                db = _mysql.connect(
                    host=db_url, user=db_username, password=db_password)
                for statement in db_provision_sql:
                    statement = replace_computed_values(
                        statement, vals)
                    db.query(statement)
            elif db_type == "postgresql":
                import psycopg2
                conn = psycopg2.connect(db_url)
                conn.set_session(autocommit=True)
                cur = conn.cursor()
                for statement in db_provision_sql:
                    statement = replace_computed_values(
                        statement, vals)
                    try:
                        cur.execute(statement)
                    except (psycopg2.errors.DuplicateObject, psycopg2.errors.DuplicateDatabase):
                        pass

            execute_post_actions(post_actions, vals)

            update_crd_status(
                group="platform.qvantel.com",
                version="v1",
                name=name,
                namespace="platform",
                plural="sqlinstallers",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "True", "SqlInstallerSucceded")
            )
        except:
            update_crd_status(
                group="platform.qvantel.com",
                version="v1",
                name=name,
                namespace="platform",
                plural="sqlinstallers",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "False", "SqlInstallerFailed", get_exception_string())
            )
            raise

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event, values):
                if values['qvantelGlue'].get('sqlinstallersCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping SqlInstallers CRD sync as it is disabled in configuration")
                    return

                k8s = get_k8s_client()

                if eventName == "Deleted":
                    # there are no "unprovision" statements in the spec currently
                    pass
                else:
                    self.executeSql(event, k8s)

            case ScheduleHook(binding, values):
                if values['qvantelGlue'].get('sqlinstallersCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping SqlInstallers CRD sync as it is disabled in configuration")
                    return

                k8s = get_k8s_client()

                for event in binding.get('snapshots', {}).get('monitor-sql-installers', []):
                    self.executeSql(event, k8s)

            case SynchronizationHook(binding, values):
                if values['qvantelGlue'].get('sqlinstallersCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping SqlInstallers CRD sync as it is disabled in configuration")
                    return

                k8s = get_k8s_client()

                for event in binding.get('objects', []):
                    self.executeSql(event, k8s)
            case _:
                print("Unknown hook data")


hook = SqlInstallersHook()
hook.handle_hook()
