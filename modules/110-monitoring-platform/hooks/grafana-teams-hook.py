#!/usr/bin/env python3

import sys
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.inline import *


class GrafanaTeamHook(Hook):
    def __init__(self):
        platformNamespace = self.get_addon_operator_config('global').get('platformNamespace','platform')
        super().__init__(str(
            {
                "configVersion": "v1",
                "kubernetes": [
                    {
                        "name": "Monitor Grafana Teams",
                        "apiVersion": "platform.qvantel.com/v1",
                        "kind": "GrafanaTeam",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "GrafanaTeamQueue",
                        "namespace": {
                            "nameSelector": {
                                "matchNames": [ platformNamespace ]
                            }
                        },
                        "allowFailure": True,
                        "jqFilter": '.spec'
                    }
                ]
            })
        )

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event):

                name = event['object']['metadata']['name']
                namespace = event['object']['metadata']['namespace']
                keycloak_admin_role = event['object']['spec'].get('keycloak-admin-role')
                
                try:
                    
                    print("Grafana Team " + name + " with admins " + keycloak_admin_role + " was evented")

                    update_crd_status(
                        group="platform.qvantel.com",
                        version="v1",
                        name=name,
                        namespace=namespace,
                        plural="grafanateams",
                        update=lambda response: updateCrdStatusCondition(
                                response, "Ready", "True", "GrafanaTeamProvisioned")
                    )
                except:
                    update_crd_status(
                        group="platform.qvantel.com",
                        version="v1",
                        name=name,
                        namespace=namespace,
                        plural="grafanateams",
                        update=lambda response: updateCrdStatusCondition(
                            response, "Ready", "False", "GrafanaTeamProvisioningFailed", get_exception_string())
                    )
                    raise
            case _:
                print("Unknown hook data")


hook = GrafanaTeamHook()
hook.handle_hook()
