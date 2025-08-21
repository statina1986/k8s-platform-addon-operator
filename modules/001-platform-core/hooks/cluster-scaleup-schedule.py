#!/usr/bin/env python3

import sys
from common.python.utils import *
from common.python.hooks import *
from common.python.vault import *
from common.python.k8s import *
import yaml

args = {
    'group': "platform.qvantel.com",
    'version': "v1",
    'name': "cluster-turndown",
    'namespace': ADDON_OPERATOR_NAMESPACE,
    'plural': "clusterturndowns"
}


class ClusterScaleupScheduleHook(Hook):
    def __init__(self):
        cm = get_config_map(ADDON_OPERATOR_NAMESPACE, ADDON_OPERATOR_CONFIG_MAP)
        try: 
            platform_core = yaml.safe_load(cm.data["platformCore"])
        except:
            platform_core = {}

        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "ScaleUp Schedule",
                        "crontab": platform_core.get("turndown", {}).get("scaleupSchedule", "0 5 31 2 *")
                    }
                ]
            })
        )

    def handle_binding(self, binding):
        match (binding):
            case ScheduleHook(context, values_json, configValues_json):
                try:
                    res = get_or_create_crd(
                        init={
                            "apiVersion": "platform.qvantel.com/v1",
                            "kind": "ClusterTurndown",
                            "metadata": {"name": "cluster-turndown"},
                            "spec": {"desiredState": "current"},
                        },
                        **args
                    )

                    if res["spec"]["desiredState"] == "up":
                        logger.info("Desired state is already 'up'. Skipping changes")
                        return

                    update_crd(
                        update=lambda response: {"spec": {"desiredState": "up"}},
                        **args
                    )

                    update_crd_status(
                        update=lambda response: updateCrdStatusCondition(
                            response,
                            "Phase",
                            "True",
                            "TriggeredScaleupOperation",
                            "Scaleup Operation has been triggered based on schedule '" + context['binding'] + "'"
                        ),
                        **args
                    )
                    update_crd_status(
                        update=lambda response: updateCrdStatusCondition(
                            response,
                            "Ready",
                            "False",
                            "TriggeredScaleupOperation",
                            "Scaleup Operation has been triggered based on schedule '" + context['binding'] + "'"
                        ),
                        **args
                    )
                except:
                    logger.info("Error during triggering scaleup")
                    raise
            case _:
                print("Unknown hook data")


hook = ClusterScaleupScheduleHook()
hook.handle_hook()
