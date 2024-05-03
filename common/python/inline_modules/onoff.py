import json
from time import sleep
import boto3
from common.python.vault import *
from common.python.k8s import *
from kubernetes.client.rest import ApiException

# SCALEUP/SCALEDOWN FUNCTIONS


def wait(time):
    sleep(time)


def get_scaling_nodegroups(cluster):
    client = boto3.client("eks")
    ng_list = client.list_nodegroups(clusterName=cluster)
    nodegroups = []
    for ng in ng_list["nodegroups"]:
        nodegroup = client.describe_nodegroup(clusterName=cluster, nodegroupName=ng)["nodegroup"]
        if nodegroup.get("labels", {}).get("cluster-controller", {}) == "true":
            continue
        else:
            nodegroups.append(nodegroup)
    return nodegroups


def scaledown_namespace(name):
    k8s_apps = get_k8s_apps_client()
    resp = k8s_apps.list_namespaced_deployment(name)
    for deployment in resp.items:
        replicas = deployment.spec.replicas
        if replicas == 0:
            logger.info("Skipping deployment" + deployment.metadata.name + " because it is already has replicas 0")
            continue
        deployment.metadata.annotations["pre-turndown-scaling-configuration"] = str(replicas)
        k8s_apps.patch_namespaced_deployment(deployment.metadata.name, deployment.metadata.namespace, {"metadata": {"annotations": deployment.metadata.annotations}})
        k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': 0}})


def scaleup_namespace(name):
    k8s_apps = get_k8s_apps_client()
    deployments = k8s_apps.list_namespaced_deployment(name)
    for deployment in deployments.items:
        replicas = deployment.metadata.annotations.get("pre-turndown-scaling-configuration", "")
        if replicas != "":
            k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': int(replicas)}})


def scaleup_deployment(name, namespace):
    k8s_apps = get_k8s_apps_client()
    deployment = k8s_apps.read_namespaced_deployment(name, namespace)
    replicas = deployment.metadata.annotations.get("pre-turndown-scaling-configuration", "")
    if replicas != "":
        k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': int(replicas)}})


def scaledown_deployment(name, namespace):
    k8s_apps = get_k8s_apps_client()
    deployment = k8s_apps.read_namespaced_deployment(name, namespace)
    replicas = deployment.spec.replicas
    if replicas == 0:
        logger.info("Skipping deployment" + deployment.metadata.name + " because it is already has replicas 0")
        return
    deployment.metadata.annotations["pre-turndown-scaling-configuration"] = str(replicas)
    k8s_apps.patch_namespaced_deployment(deployment.metadata.name, deployment.metadata.namespace, {"metadata": {"annotations": deployment.metadata.annotations}})
    k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': 0}})


def scaleup_nodegorups(clusterName):
    nodegroups = get_scaling_nodegroups(clusterName)
    for ng in nodegroups:
        scaleup_nodegorup(ng)


def scaleup_nodegorup(ng):
    boto3_client = boto3.client("eks")
    previous_scaling_config = ng.get("tags", {}).get("pre-turndown-scaling-configuration", "")

    if previous_scaling_config == "":
        return

    update_op = boto3_client.update_nodegroup_config(
        clusterName=ng["clusterName"],
        nodegroupName=ng["nodegroupName"],
        scalingConfig=json.loads(base64.b64decode(previous_scaling_config).decode('utf-8'))
    )

    update_op_id = update_op["update"]["id"]

    while update_op["update"]["status"] == "InProgress":
        sleep(20)
        update_op = boto3_client.describe_update(
            name=ng["clusterName"],
            updateId=update_op_id,
            nodegroupName=ng["nodegroupName"],
        )


def scaledown_nodegorups(clusterName):
    nodegroups = get_scaling_nodegroups(clusterName)
    for ng in nodegroups:
        scaledown_nodegorup(ng)


def scaledown_nodegorup(ng):
    boto3_client = boto3.client("eks")

    if ng["scalingConfig"]["desiredSize"] == 0:
        logger.info("Skipping scaledown of the node " + ng["nodegroupName"] + ":because it is already has desiredSize 0")
        return

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
    update_op_id = update_op["update"]["id"]
    while update_op["update"]["status"] == "InProgress":
        sleep(20)
        update_op = boto3_client.describe_update(
            name=ng["clusterName"],
            updateId=update_op_id,
            nodegroupName=ng["nodegroupName"],
        )
