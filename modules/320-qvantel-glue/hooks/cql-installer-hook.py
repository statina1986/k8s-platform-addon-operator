#!/usr/bin/env python3

from gevent import monkey
monkey.patch_all()

import sys

from common.python.utils import *
from common.python.hooks import *
from common.python.vault import *
from common.python.k8s import *
from common.python.inline import *

from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider


class CqlInstallersHook(Hook):
    def __init__(self):
        qvantelGlue = self.get_addon_operator_config("qvantelGlue")
        platformNamespace = self.get_addon_operator_config('global').get('platformNamespace', 'platform')
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "cql-installers-periodic-checking",
                        "crontab": qvantelGlue.get("cqlinstallersCrdSync", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-cql-installers"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-cql-installers",
                        "apiVersion": "platform.qvantel.com/v1",
                        "kind": "CqlInstallers",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "CqlInstallersQueue",
                        "namespace": qvantelGlue.get("cqlinstallersCrdSync", {}).get("namespaceSelector", {
                            "nameSelector": {
                                "matchNames": [platformNamespace]
                            }
                        }),
                        "allowFailure": True,
                        "jqFilter": '.spec'
                    }
                ]
            })
        )

    def executeCql(self, event, k8s):
        forceGeneration = event['object']['spec'].get('forceGeneration', 1)
        try:
            name = event['object']['metadata']['name']
            namespace = event['object']['metadata']['namespace']
            db_provision_cql = event['object']['spec']['db-provision-cql']
            db_secret = event['object']['spec'].get(
                'db-secret-name', '')
            db_username = event['object']['spec'].get(
                'db-username', '')
            db_password = event['object']['spec'].get(
                'db-password', '')
            db_url = event['object']['spec']['db-url']
            computed_values = event['object']['spec'].get(
                'computed-values', {})
            post_actions = event['object']['spec'].get(
                'post-actions', {})            

            vals = get_computed_values(computed_values)

            db_url = replace_computed_values(db_url, vals)

            if db_secret != '':
                secret = k8s.read_namespaced_secret(
                    db_secret, namespace).data
                db_username = base64.b64decode(
                    secret['username']).decode('utf-8')
                db_password = base64.b64decode(
                    secret['password']).decode('utf-8')

            db_username = replace_computed_values(
                db_username, vals)
            db_password = replace_computed_values(
                db_password, vals)
            
            auth_provider = PlainTextAuthProvider(username=db_username, password=db_password)
            cluster = Cluster([db_url],auth_provider=auth_provider)
            session = cluster.connect()
            for statement in db_provision_cql:
                statement = replace_computed_values(
                    statement, vals)
                session.execute(statement)                    

            execute_post_actions(post_actions, vals)

            update_crd_status(
                group="platform.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="cqlinstallers",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "True", "CqlInstallerSucceded")
            )
        except:
            update_crd_status(
                group="platform.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="cqlinstallers",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "False", "CqlInstallerFailed", get_exception_string())
            )
            # CqlInstaller has failed more than 10 times in a row, imposing throttling delay of 10 sec
            if forceGeneration > 10:
                time.sleep(10)
            update_crd(
                group="platform.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="cqlinstallers",
                update=lambda response: {"spec": {"forceGeneration": response['spec']['forceGeneration'] + 1}}
            )

    def checkIfReady(self, event):
        conditions = event['object'].get('status', {}).get('conditions', [])
        for idx, item in enumerate(conditions):
            if ((item["type"] == "Ready") and (item["status"] == "True")):
                return True
        return False

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event, values):
                if values['qvantelGlue'].get('cqlinstallersCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping CqlInstallers CRD sync as it is disabled in configuration")
                    return

                k8s = get_k8s_client()

                if eventName == "Deleted":
                    # there are no "unprovision" statements in the spec currently
                    pass
                else:
                    self.executeCql(event, k8s)

            case ScheduleHook(binding, values):
                if values['qvantelGlue'].get('cqlinstallersCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping CqlInstallers CRD sync as it is disabled in configuration")
                    return

                k8s = get_k8s_client()

                for event in binding.get('snapshots', {}).get('monitor-cql-installers', []):
                    # Skipping 'Ready' Installers from scheduled execution as those were already applied
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        print("Skipping CqlInstaller " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.executeCql(event, k8s)

            case SynchronizationHook(binding, values):
                if values['qvantelGlue'].get('cqlinstallersCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping CqlInstallers CRD sync as it is disabled in configuration")
                    return

                k8s = get_k8s_client()

                for event in binding.get('objects', []):
                    # Skipping 'Ready' Installers from synchronization execution as those were already applied
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        print("Skipping CqlInstaller " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.executeCql(event, k8s)

            case _:
                print("Unknown hook data")


hook = CqlInstallersHook()
hook.handle_hook()
