import json
from time import sleep
import boto3
from common.python.vault import *
from common.python.k8s import *
from kubernetes.client.rest import ApiException
from concurrent.futures import ThreadPoolExecutor

# SCALEUP/SCALEDOWN

# UTILITY FUNCTIONS
def wait(time):
    sleep(time)

# K8S WORKLOAD SCALING FUNCTIONS

def scaledown_deployment(name, namespace):
    """
    Scale down a single deployment, storing the current replica count as an annotation.
    """
    k8s_apps = get_k8s_apps_client()
    logger.info("Scaling down deployment " + name + " in namespace " + namespace)
    deployment = k8s_apps.read_namespaced_deployment(name, namespace)
    replicas = deployment.spec.replicas
    if replicas == 0:
        logger.info("Skipping deployment " + deployment.metadata.name + " because it already has 0 replicas")
        return
    deployment.metadata.annotations["pre-turndown-scaling-configuration"] = str(replicas)
    try:
        k8s_apps.patch_namespaced_deployment(deployment.metadata.name, deployment.metadata.namespace, {"metadata": {"annotations": deployment.metadata.annotations}})
        k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': 0}})
    except ApiException as e:
        print(f"Failed to patch deployment {deployment.metadata.name}: {e}")

def scaledown_namespace_deployments(name):
    """
    Scale down all deployments in the specified namespace, except 'addon-operator'.
    Save the original replica count as an annotation on each deployment.
    """
    k8s_apps = get_k8s_apps_client()
    resp = k8s_apps.list_namespaced_deployment(name)
    logger.info("Scaling down deployments in namespace " + name)
    for deployment in resp.items:
        replicas = deployment.spec.replicas
        if replicas == 0:
            logger.info("Skipping deployment " + deployment.metadata.name + " because it already has 0 replicas")
            continue
        if deployment.metadata.name == "addon-operator":
            logger.info("Skipping deployment " + deployment.metadata.name + " as it controls the scaling operations")
            continue
        # Ensure annotations dict exists
        if deployment.metadata.annotations is None:
            deployment.metadata.annotations = {}
        deployment.metadata.annotations["pre-turndown-scaling-configuration"] = str(replicas)
        try:
            k8s_apps.patch_namespaced_deployment(deployment.metadata.name, deployment.metadata.namespace, {"metadata": {"annotations": deployment.metadata.annotations}})
            k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': 0}})
        except ApiException as e:
            print(f"Failed to patch deployment {deployment.metadata.name}: {e}")

def scaledown_namespace_statefulsets(name):
    """
    Scale down all statefulsets in the specified namespace.
    Save the original replica count as an annotation on each statefulset.
    """
    k8s_apps = get_k8s_apps_client()
    resp = k8s_apps.list_namespaced_stateful_set(name)
    logger.info("Scaling down statefulsets in namespace " + name)
    for statefulset in resp.items:
        replicas = statefulset.spec.replicas
        if replicas == 0:
            logger.info("Skipping statefulset " + statefulset.metadata.name + " because it already has 0 replicas")
            continue
        # Ensure annotations dict exists
        if statefulset.metadata.annotations is None:
            statefulset.metadata.annotations = {}
        statefulset.metadata.annotations["pre-turndown-scaling-configuration"] = str(replicas)
        try:
            k8s_apps.patch_namespaced_stateful_set(statefulset.metadata.name, statefulset.metadata.namespace, {"metadata": {"annotations": statefulset.metadata.annotations}})
            k8s_apps.patch_namespaced_stateful_set_scale(statefulset.metadata.name, statefulset.metadata.namespace, {'spec': {'replicas': 0}})
        except ApiException as e:
            print(f"Failed to patch statefulset {statefulset.metadata.name}: {e}")

def delete_namespace_strimzipodsets(name):
    """
    Delete all StrimziPodSet resources from a given namespace.
    This is required for Kafka Strimzi clusters before scaling down.
    """
    k8s_crd = get_k8s_crd_client()
    logger.info("Deleting StrimziPodSets in namespace " + name)

    # Defining the group, version, and plural for StrimziPodSet
    group = "core.strimzi.io"
    version = "v1beta2"
    plural = "strimzipodsets"
    namespace = name

    try:
        podsets = k8s_crd.list_namespaced_custom_object(
            group=group,
            version=version,
            namespace=name,
            plural=plural
        )
    except client.exceptions.ApiException as e:
        print(f"Failed to list StrimziPodSets in namespace {namespace}: {e}")
        return

    for podset in podsets.get("items", []):
        podsetname = podset["metadata"]["name"]
        try:
            k8s_crd.delete_namespaced_custom_object(
                group=group,
                version=version,
                namespace=namespace,
                plural=plural,
                name=podsetname,
                body=client.V1DeleteOptions()
            )
        except client.exceptions.ApiException as e:
            print(f"Failed to delete StrimziPodSet {podsetname}: {e}")

def scaleup_deployment(name, namespace):
    """
    Scale up a single deployment using the saved replica count from annotations.
    """
    k8s_apps = get_k8s_apps_client()
    logger.info("Scaling up deployment " + name + " in namespace " + namespace)
    deployment = k8s_apps.read_namespaced_deployment(name, namespace)
    replicas = deployment.metadata.annotations.get("pre-turndown-scaling-configuration", "")
    if replicas != "":
        try:
            k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': int(replicas)}})
        except ApiException as e:
            print(f"Failed to patch deployment {deployment.metadata.name}: {e}")

def scaleup_namespace_deployments(name):
    """
    Scale up all deployments in the specified namespace using previously
    stored replica counts from annotations.
    """
    k8s_apps = get_k8s_apps_client()
    logger.info("Scaling up deployments in namespace " + name)
    deployments = k8s_apps.list_namespaced_deployment(name)
    for deployment in deployments.items:
        replicas = deployment.metadata.annotations.get("pre-turndown-scaling-configuration", "")
        if replicas != "":
            try:
                k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': int(replicas)}})
            except ApiException as e:
                print(f"Failed to patch deployment {deployment.metadata.name}: {e}")

def scaleup_namespace_statefulsets(name):
    """
    Scale up all statefulsets in the specified namespace using previously
    stored replica counts from annotations.
    """
    k8s_apps = get_k8s_apps_client()
    logger.info("Scaling up statefulsets in namespace " + name)
    statefulsets = k8s_apps.list_namespaced_stateful_set(name)
    for statefulset in statefulsets.items:
        replicas = statefulset.metadata.annotations.get("pre-turndown-scaling-configuration", "")
        if replicas != "":
            try:
                k8s_apps.patch_namespaced_stateful_set_scale(statefulset.metadata.name, statefulset.metadata.namespace, {'spec': {'replicas': int(replicas)}})
            except ApiException as e:
                print(f"Failed to patch statefulset {statefulset.metadata.name}: {e}")

# EKS NODE SCALING FUNCTIONS

def get_scaling_nodegroups(cluster):
    """
    Retrieve all nodegroups for a given EKS cluster,
    excluding any that have the label 'cluster-controller=true'.
    """
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

def scaledown_nodegroups(clusterName):
    """
    Scale down all matching nodegroups in a cluster using stored scaling config from tags.
    """
    nodegroups = get_scaling_nodegroups(clusterName)

    monitoring_tasks = []

    with ThreadPoolExecutor(max_workers=len(nodegroups)) as executor:
        for ng in nodegroups:
            result = initiate_scaledown(ng)
            if result:
                # Submit monitoring task to run in background
                future = executor.submit(
                    monitor_scaledown,
                    result["clusterName"],
                    result["nodegroupName"],
                    result["updateId"]
                )
                monitoring_tasks.append(future)
    ## Wait for monitoring to finish before leaving function
    for task in monitoring_tasks:
        try:
            task.result()
        except Exception as e:
            print(f"Monitoring task failed: {e}")
    logger.info("Nodegroup(s) scale-down operations complete!")

def initiate_scaledown(ng):
    """
    Triggers the scale-down of the nodegroup and returns the update ID.
    """
    eks_client = boto3.client("eks")

    if ng["scalingConfig"]["desiredSize"] == 0:
        logger.info("Skipping scale-down of nodegroup " + ng["nodegroupName"] + " because it already has desiredSize 0")
        return

    # Persist current scaling config in a base64-encoded tag for future scale-up
    eks_client.tag_resource(
        resourceArn=ng["nodegroupArn"],
        tags={
            'pre-turndown-scaling-configuration': base64.b64encode(json.dumps(ng["scalingConfig"]).encode('utf-8')).decode()
        }
    )

    # Trigger update
    update_op = eks_client.update_nodegroup_config(
        clusterName=ng["clusterName"],
        nodegroupName=ng["nodegroupName"],
        scalingConfig={
            "minSize": 0,
            "maxSize": 1,
            "desiredSize": 0,
        },
    )

    logger.info("Initiated scale-down for nodegroup " + ng["nodegroupName"])
    return {
        "clusterName": ng["clusterName"],
        "nodegroupName": ng["nodegroupName"],
        "updateId": update_op["update"]["id"]
    }

def monitor_scaledown(clusterName, nodegroupName, updateId):
    """
    Polls EKS update and EC2 instances until they are terminated
    """
    eks_client = boto3.client("eks")
    ec2_client = boto3.client("ec2")

    # Wait for EKS update
    while True:
        update = eks_client.describe_update(
            name=clusterName,
            updateId=updateId,
            nodegroupName=nodegroupName,
        )["update"]

        if update["status"] != "InProgress":
            break

        logger.info("Waiting for EKS update to complete on nodegroup " + nodegroupName)
        sleep(20)

    logger.info("EKS update complete for nodegroup " + nodegroupName)

    # Wait for EC2 instances to terminate
    while True:
        filters = [
            {"Name": "tag:eks:cluster-name", "Values": [clusterName]},
            {"Name": "tag:eks:nodegroup-name", "Values": [nodegroupName]},
            {"Name": "instance-state-name", "Values": ["pending", "running", "shutting-down", "stopping", "stopped"]}
        ]

        instances = ec2_client.describe_instances(Filters=filters)
        active_instances = sum(len(res["Instances"]) for res in instances["Reservations"])

        if active_instances == 0:
            logger.info("All EC2 instances in nodegroup " + nodegroupName + " have been terminated")
            break

        logger.info("Waiting for " + str(active_instances) + " EC2 instance(s) in nodegroup " + nodegroupName + " to terminate, sleeping for 10 seconds ...")
        sleep(10)

def scaleup_nodegroups(clusterName):
    """
    Scale up all matching nodegroups in a cluster using stored scaling config from tags.
    """
    nodegroups = get_scaling_nodegroups(clusterName)

    monitoring_tasks = []

    with ThreadPoolExecutor(max_workers=len(nodegroups)) as executor:
        for ng in nodegroups:
            result = initiate_scaleup(ng)
            if result:
                # Submit monitoring task to run in background
                future = executor.submit(
                    monitor_scaleup,
                    result["clusterName"],
                    result["nodegroupName"],
                    result["updateId"]
                )
                monitoring_tasks.append(future)
    ## Wait for monitoring to finish before leaving function
    for task in monitoring_tasks:
        try:
            task.result()
        except Exception as e:
            print(f"Monitoring task failed: {e}")
    logger.info("Nodegroup(s) scaleup operations complete!")

def initiate_scaleup(ng):
    """
    Scale up a single nodegroup based on stored configuration in tags.
    """
    eks_client = boto3.client("eks")

    previous_scaling_config = ng.get("tags", {}).get("pre-turndown-scaling-configuration", "")
    if not previous_scaling_config:
        logger.info("No previous scaling config found for nodegroup " + ng["nodegroupName"] + ", skipping scale-up")
        return

    scaling_config = json.loads(base64.b64decode(previous_scaling_config).decode("utf-8"))

    # Trigger update
    update_op = eks_client.update_nodegroup_config(
        clusterName=ng["clusterName"],
        nodegroupName=ng["nodegroupName"],
        scalingConfig=scaling_config
    )

    logger.info("Initiated scale-up for nodegroup " + ng["nodegroupName"])
    return {
        "clusterName": ng["clusterName"],
        "nodegroupName": ng["nodegroupName"],
        "updateId": update_op["update"]["id"]
    }

def monitor_scaleup(clusterName, nodegroupName, updateId):
    """
    Polls EKS update and EC2 instances until they are running and ready
    """
    eks_client = boto3.client("eks")
    ec2_client = boto3.client("ec2")

    # Wait for EKS update
    while True:
        update = eks_client.describe_update(
            name=clusterName,
            updateId=updateId,
            nodegroupName=nodegroupName,
        )["update"]

        if update["status"] != "InProgress":
            break

        logger.info("Waiting for EKS update to complete on nodegroup " + nodegroupName)
        sleep(20)

    logger.info("EKS update complete for nodegroup " + nodegroupName)

    # Get desired size from the nodegroup config
    nodegroup = eks_client.describe_nodegroup(clusterName=clusterName, nodegroupName=nodegroupName)["nodegroup"]
    desired_size = nodegroup["scalingConfig"]["desiredSize"]

    # Wait for EC2 instances to start
    while True:
        filters = [
            {"Name": "tag:eks:cluster-name", "Values": [clusterName]},
            {"Name": "tag:eks:nodegroup-name", "Values": [nodegroupName]},
            {"Name": "instance-state-name", "Values": ["running"]}
        ]

        instances = ec2_client.describe_instances(Filters=filters)
        instance_ids = [
            i["InstanceId"]
            for r in instances["Reservations"]
            for i in r["Instances"]
        ]

        active_instances = len(instance_ids)

        if str(active_instances) == str(desired_size):
            # Check instance status checks
            status_response = ec2_client.describe_instance_status(InstanceIds=instance_ids)
            ready_instances = [
                s["InstanceId"]
                for s in status_response["InstanceStatuses"]
                if s["InstanceStatus"]["Status"] == "ok" and s["SystemStatus"]["Status"] == "ok"
            ]
            if str(len(ready_instances)) == str(desired_size):
                logger.info("All EC2 instances in nodegroup " + nodegroupName + " are running and ready")
                break
            else:
                logger.info(str(len(ready_instances)) + "/" + str(desired_size) + " instances are ready in nodegroup " + nodegroupName + ", sleeping for 10 seconds ...")
                sleep(10)
        else:
            logger.info("Waiting for " + str(desired_size) + " EC2 instances in nodegroup " + nodegroupName + " to start, currently " + str(active_instances) + " running, sleeping for 10 seconds ...")
            sleep(10)