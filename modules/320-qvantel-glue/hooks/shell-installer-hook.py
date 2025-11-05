#!/usr/bin/env python3

import sys
import subprocess
from common.python.utils import *
from common.python.hooks import *
from common.python.vault import *
from common.python.k8s import *
from common.python.inline import *



class ShellInstallersHook(Hook):
    def __init__(self):
        qvantelGlue = self.get_addon_operator_config("qvantelGlue")
        platformNamespace = self.get_addon_operator_config('global').get('platformNamespace', 'platform')
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "shell-installers-periodic-checking",
                        "crontab": qvantelGlue.get("shellinstallersCrdSync", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-shell-installers"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-shell-installers",
                        "apiVersion": "platform.qvantel.com/v1",
                        "kind": "ShellInstallers",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "ShellInstallersQueue",
                        "namespace": qvantelGlue.get("shellinstallersCrdSync", {}).get("namespaceSelector", {
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

    def executeShell(self, event, k8s):
        try:
            name = event['object']['metadata']['name']
            namespace = event['object']['metadata']['namespace']
            provision_commands = event['object']['spec']['provision-commands']
            computed_values = event['object']['spec'].get('computed-values', {})
            post_actions = event['object']['spec'].get('post-actions', {})
            forceGeneration = event['object']['spec'].get('forceGeneration', 1)
            env = event['object']['spec'].get('env', {})
 
            vals = get_computed_values(computed_values)

            final_env = {}
            
            for key, value in env.items():
                key = replace_computed_values(key, vals)
                value = replace_computed_values(value, vals)
                final_env[key] = value                

            for statement in provision_commands:                
                statement = replace_computed_values(statement, vals)
                subprocess.run(statement, shell=True, check=True, env=final_env)

            execute_post_actions(post_actions, vals)

            update_crd_status(
                group="platform.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="shellinstallers",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "True", "ShellInstallerSucceded")
            )
        except:
            update_crd_status(
                group="platform.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="shellinstallers",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "False", "ShellInstallerFailed", get_exception_string())
            )
            # ShellInstaller has failed more than 10 times in a row, imposing throttling delay of 10 sec
            if forceGeneration > 10:
                time.sleep(10)
            update_crd(
                group="platform.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="shellinstallers",
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
                if values['qvantelGlue'].get('shellinstallersCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping ShellInstallers CRD sync as it is disabled in configuration")
                    return

                k8s = get_k8s_client()

                if eventName == "Deleted":
                    # there are no "unprovision" statements in the spec currently
                    pass
                else:
                    self.executeShell(event, k8s)

            case ScheduleHook(binding, values):
                if values['qvantelGlue'].get('shellinstallersCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping ShellInstallers CRD sync as it is disabled in configuration")
                    return

                k8s = get_k8s_client()

                for event in binding.get('snapshots', {}).get('monitor-shell-installers', []):
                    # Skipping 'Ready' Installers from scheduled execution as those were already applied
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping ShellInstaller " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.executeShell(event, k8s)

            case SynchronizationHook(binding, values):
                if values['qvantelGlue'].get('shellinstallersCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping ShellInstallers CRD sync as it is disabled in configuration")
                    return

                k8s = get_k8s_client()

                for event in binding.get('objects', []):
                    # Skipping 'Ready' Installers from synchronization execution as those were already applied
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping ShellInstaller " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.executeShell(event, k8s)

            case _:
                print("Unknown hook data")


hook = ShellInstallersHook()
hook.handle_hook()
