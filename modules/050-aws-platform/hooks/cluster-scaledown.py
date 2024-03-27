#!/usr/bin/env python3

import sys
from time import sleep
import boto3
import yaml
from common.python.utils import *
from common.python.hooks import *
from common.python.vault import *
from common.python.k8s import *
from common.python.inline import *

boto3_client = boto3.client("eks")

args = {
    'group': "platform.qvantel.com",
    'version': "v1",
    'name': "cluster-turndown",
    'namespace': ADDON_OPERATOR_NAMESPACE,
    'plural': "clusterturndowns"
}


def get_scaling_nodegroups(cluster):
    ng_list = boto3_client.list_nodegroups(clusterName=cluster)
    nodegroups = []
    for ng in ng_list["nodegroups"]:
        nodegroup = boto3_client.describe_nodegroup(clusterName=cluster, nodegroupName=ng)["nodegroup"]
        if nodegroup.get("labels", {}).get("cluster-controller", {}) == "true":
            continue
        else:
            nodegroups.append(nodegroup)
    return nodegroups


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

                    name = event["object"]["metadata"]["name"]
                    clusterName = values['awsPlatform']['clusterName']
                    desiredState = event["object"]["spec"]["desiredState"]
                    generation = event.get("object", {}).get("metadata", {}).get("generation", 0)
                    observed_generation = event.get("object", {}).get("status", {}).get("observedGeneration", 0)

                    if generation <= observed_generation:
                        logger.info("Skipping generation : " + str(generation))
                        return

                    k8s_crd = get_k8s_crd_client()
                    k8s_apps = get_k8s_apps_client()

                    k8s_crd.patch_namespaced_custom_object_status(
                        body={
                            "status": {
                                "observedGeneration": generation
                            }
                        },
                        **args
                    )

                    if desiredState == "down":

                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Phase",
                                "True",
                                "ScalingDownNamespaces",
                                "Scaling Down namespace : " + "qvantel",
                            ),
                            **args
                        )

                        resp = k8s_apps.list_namespaced_deployment("qvantel")
                        for deploy in resp.items:
                            replicas = deploy.spec.replicas
                            deploy.metadata.annotations["pre-turndown-scaling-configuration"] = str(replicas)
                            k8s_apps.patch_namespaced_deployment(deploy.metadata.name, deploy.metadata.namespace, {"metadata": {"annotations": deploy.metadata.annotations}})
                            k8s_apps.patch_namespaced_deployment_scale(deploy.metadata.name, deploy.metadata.namespace, {'spec': {'replicas': 0}})

                        nodegroups = get_scaling_nodegroups(clusterName)

                        for ng in nodegroups:
                            boto3_client.tag_resource(
                                resourceArn=ng["nodegroupArn"],
                                tags={
                                    'pre-turndown-scaling-configuration': base64.b64encode(json.dumps(ng["scalingConfig"]).encode('utf-8')).decode()
                                }
                            )
                            update_op = boto3_client.update_nodegroup_config(
                                clusterName=ng["clusterName"],
                                nodegroupName=ng["nodegroupName"],
                                scalingConfig={
                                    "minSize": 0,
                                    "maxSize": 1,
                                    "desiredSize": 0,
                                },
                            )

                            update_crd_status(
                                update=lambda response: updateCrdStatusCondition(
                                    response,
                                    "Phase",
                                    "True",
                                    "ScalingDownNodeGroups",
                                    "Scaling Down nodegroup : " + ng["nodegroupName"],
                                ),
                                **args
                            )
                            update_op_id = update_op["update"]["id"]
                            while update_op["update"]["status"] == "InProgress":
                                sleep(20)
                                update_op = boto3_client.describe_update(
                                    name=ng["clusterName"],
                                    updateId=update_op_id,
                                    nodegroupName=ng["nodegroupName"],
                                )

                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Phase",
                                "True",
                                "ScaleDownNodeGroupsCompleted",
                                "ScaleDownNodeGroupsCompleted",
                            ),
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
                            **args
                        )

                    if desiredState == "up":
                        nodegroups = get_scaling_nodegroups(clusterName)

                        for ng in nodegroups:

                            previous_scaling_config = ng.get("tags", {}).get("pre-turndown-scaling-configuration", "")
                            if previous_scaling_config == "":
                                continue

                            update_op = boto3_client.update_nodegroup_config(
                                clusterName=ng["clusterName"],
                                nodegroupName=ng["nodegroupName"],
                                scalingConfig=json.loads(base64.b64decode(previous_scaling_config).decode('utf-8'))
                            )

                            update_crd_status(
                                update=lambda response: updateCrdStatusCondition(
                                    response,
                                    "Phase",
                                    "True",
                                    "ScalingUpNodeGroups",
                                    "Scaling Up nodegroup : " + ng["nodegroupName"],
                                ),
                                **args
                            )
                            update_op_id = update_op["update"]["id"]
                            while update_op["update"]["status"] == "InProgress":
                                sleep(20)
                                update_op = boto3_client.describe_update(
                                    name=ng["clusterName"],
                                    updateId=update_op_id,
                                    nodegroupName=ng["nodegroupName"],
                                )

                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Phase",
                                "True",
                                "ScaleUpNodeGroupsCompleted",
                                "ScaleUpNodeGroupsCompleted",
                            ),
                            **args
                        )

                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Phase",
                                "True",
                                "WaitingForPlatformReadiness",
                                "WaitingForPlatformReadiness",
                            ),
                            **args
                        )

                        sleep(120)

                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Phase",
                                "True",
                                "ScalingUpNamespaces",
                                "Scaling Up namespace : " + "qvantel",
                            ),
                            **args
                        )

                        deployments = k8s_apps.list_namespaced_deployment("qvantel")
                        for deploy in deployments.items:
                            replicas = deploy.metadata.annotations.get("pre-turndown-scaling-configuration", "")
                            if replicas != "":
                                # deploy["metadata"]["annotations"].append("pre-turndown-scaling-configuration", str(replicas))
                                # k8s_apps.patch_namespaced_deployment(deploy["metadata"]["name"], deploy["metadata"]["namespace"], {"metadata": {"annotations": deploy["metadata"]["annotations"]}})
                                k8s_apps.patch_namespaced_deployment_scale(deploy.metadata.name, deploy.metadata.namespace, {'spec': {'replicas': int(replicas)}})

                        update_crd_status(
                            update=lambda response: updateCrdStatusCondition(
                                response,
                                "Ready",
                                "True",
                                "ScaleUpCompleted",
                                "ScaleUp Operation has been completed",
                            ),
                            **args
                        )
                except:
                    logger.info("Error during triggering turndown")
                    raise
            case _:
                print("Unknown hook data")


hook = ClusterScaledownHook()
hook.handle_hook()
