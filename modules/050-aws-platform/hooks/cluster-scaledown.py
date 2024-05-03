#!/usr/bin/env python3

import sys
from time import sleep
import yaml
from common.python.utils import *
from common.python.hooks import *
from common.python.vault import *
from common.python.k8s import *
from common.python.inline import *

k8s_crd = get_k8s_crd_client()

args = {
    'group': "platform.qvantel.com",
    'version': "v1",
    'namespace': ADDON_OPERATOR_NAMESPACE,
    'plural': "clusterturndowns"
}


def scale_strategy(clusterName, crdName, strategy):

    vals = {
        "clusterName": clusterName
    }

    for step in strategy:        
        action = replace_computed_values(step['expression'], vals)        
        vals[step['name']] = eval(action)
        update_crd_status(
            update=lambda response: updateCrdStatusCondition(
                response,
                "Phase",
                "True",
                step['name'],
                step['name'],
            ),
            name=crdName,
            **args
        )


class ClusterScaledownHook(Hook):
    def __init__(self):
        cm = get_config_map(ADDON_OPERATOR_NAMESPACE, "addon-operator")
        super().__init__(
            """
configVersion: v1
kubernetes:
- name: "Monitor ClusterTurndowns"
  apiVersion: platform.qvantel.com/v1
  kind: ClusterTurndown
  executeHookOnEvent: [ "Added", "Modified" ]
  queue: ClusterTurndownQueue
  allowFailure: true
"""
        )

    def handle_binding(self, binding):

        match (binding):
            case EventHook(eventName, event, values, config_values):
                try:
                    cm = get_config_map(ADDON_OPERATOR_NAMESPACE, "addon-operator")
                    platform_core = yaml.safe_load(cm.data["platformCore"])
                    if platform_core.get("turndown", {}).get("enabled", "false") != "true":
                        logger.info("Turndown is disabled. Skipping operation.")
                        return

                    crdName = event["object"]["metadata"]["name"]
                    clusterName = values['awsPlatform']['clusterName']
                    desiredState = event["object"]["spec"]["desiredState"]
                    generation = event.get("object", {}).get("metadata", {}).get("generation", 0)
                    observed_generation = event.get("object", {}).get("status", {}).get("observedGeneration", 0)
                    last_state = event.get("object", {}).get("status", {}).get("state", 0)

                    if generation <= observed_generation:
                        logger.info("Skipping generation : " + str(generation))
                        return

                    k8s_crd.patch_namespaced_custom_object_status(
                        body={
                            "status": {
                                "observedGeneration": generation
                            }
                        },
                        name=crdName,
                        **args
                    )

                    default_strategy_up = platform_core.get("turndown", {}).get("defaultStrategy", {}).get("up", {})
                    default_strategy_down = platform_core.get("turndown", {}).get("defaultStrategy", {}).get("down", {})

                    strategy_up = event["object"]["spec"].get("strategy", {}).get("up", default_strategy_up)
                    strategy_down = event["object"]["spec"].get("strategy", {}).get("down", default_strategy_down)

                    if desiredState == "down":
                        if last_state == "down":
                            logger.info("Skipping scaledown : Cluster is already in down state")
                            return

                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Ready",
                                "False",
                                "TurndownTriggered",
                                "Turndown Operation has been triggered",
                            ),
                            name=crdName,
                            **args
                        )

                        scale_strategy(clusterName, crdName, strategy_down)

                        k8s_crd.patch_namespaced_custom_object_status(
                            body={
                                "status": {
                                    "state": "down"
                                }
                            },
                            name=crdName,
                            **args
                        )

                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Ready",
                                "True",
                                "TurndownCompleted",
                                "Turndown Operation has been completed",
                            ),
                            name=crdName,
                            **args
                        )

                        return

                    elif desiredState == "up":
                        if last_state == "up":
                            logger.info("Skipping scaleup : Cluster is already in up state")
                            return

                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Ready",
                                "False",
                                "ScaleUpTriggered",
                                "ScaleUp Operation has been triggered",
                            ),
                            name=crdName,
                            **args
                        )

                        scale_strategy(clusterName, crdName, strategy_up)

                        k8s_crd.patch_namespaced_custom_object_status(
                            body={
                                "status": {
                                    "state": "up"
                                }
                            },
                            name=crdName,
                            **args
                        )
                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Ready",
                                "True",
                                "ScaleUpCompleted",
                                "ScaleUp Operation has been completed",
                            ),
                            name=crdName,
                            **args
                        )
                except:
                    logger.info("Error during triggering turndown")
                    raise
            case _:
                print("Unknown hook data")

hook = ClusterScaledownHook()
hook.handle_hook()
