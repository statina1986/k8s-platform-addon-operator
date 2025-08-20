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
    deployment = k8s_apps.read_namespaced_deployment(name, namespace)
    replicas = deployment.spec.replicas
    if replicas == 0:
        logger.info("Skipping deployment " + deployment.metadata.name + " in namespace " +  deployment.metadata.namespace + " because it already has 0 replicas")
        return
    if deployment.metadata.name == "addon-operator":
        logger.info("Skipping deployment " + deployment.metadata.name + " in namespace " +  deployment.metadata.namespace + " as it controls the scaling operations")
        return
    if deployment.metadata.name == "mariadb-metrics":
        logger.info("Skipping deployment " + deployment.metadata.name + " in namespace " +  deployment.metadata.namespace + " as it is controlled by MariaDB cluster")
        return
    # Ensure annotations dict exists
    if deployment.metadata.annotations is None:
        deployment.metadata.annotations = {}
    deployment.metadata.annotations["pre-turndown-scaling-configuration"] = str(replicas)
    try:
        logger.debug("Scaling down deployment " + deployment.metadata.name + " in namespace " + deployment.metadata.namespace)
        k8s_apps.patch_namespaced_deployment(deployment.metadata.name, deployment.metadata.namespace, {"metadata": {"annotations": deployment.metadata.annotations}})
        k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': 0}})
    except ApiException as e:
        logger.info("Failed to patch deployment " + deployment.metadata.name + " : " + e)

def scaledown_namespace_deployments(namespace):
    """
    Scale down all deployments in the specified namespace to 0 replicas.
    Waits for all deployments to scale down and terminate.
    """
    k8s_apps = get_k8s_apps_client()
    try:
        deployments = k8s_apps.list_namespaced_deployment(namespace)
    except ApiException as e:
        logger.info("Failed to list deployments in namespace " + namespace + ": " + str(e))
        return

    logger.info("Scaling down deployments in namespace " + namespace)

    for deployment in deployments.items:
        scaledown_deployment(deployment.metadata.name, namespace)

    while True:
        all_scaled_down = True
        try:
            current_deployments = k8s_apps.list_namespaced_deployment(namespace)
        except ApiException as e:
            logger.info("Error fetching deployment status: " + str(e))
            break

        for deploy in current_deployments.items:
            name = deploy.metadata.name
            if name == "addon-operator":
                logger.info("Skipping checking deployment " + name + " in namespace " + namespace + " as it controls the scaling operations")
                continue
            if name == "mariadb-metrics":
                logger.info("Skipping checking deployment " + name + " in namespace " + namespace + " as it is controlled by MariaDB cluster")
                continue
            desired = deploy.spec.replicas or 0
            ready = deploy.status.ready_replicas or 0
            if ready > 0:
                logger.info("Deployment " + name +  " in namespace " + namespace + " not yet scaled down: " + str(ready) + "/" + str(desired))
                all_scaled_down = False
            else:
                logger.debug("Deployment " + name + " in namespace " + namespace + " scaled down: " + str(ready) + "/" + str(desired))

        if all_scaled_down:
            logger.info("All deployments scaled down successfully in namespace " + namespace)
            break
        sleep(10)

def scaledown_statefulset(name, namespace):
    """
    Scale down a single statefulset, storing the current replica count as an annotation.
    """
    k8s_apps = get_k8s_apps_client()
    statefulset = k8s_apps.read_namespaced_stateful_set(name, namespace)
    replicas = statefulset.spec.replicas
    if replicas == 0:
        logger.info("Skipping statefulset " + statefulset.metadata.name + " in namespace " + statefulset.metadata.namespace + " because it already has 0 replicas")
        return
    # Ensure annotations dict exists
    if statefulset.metadata.annotations is None:
        statefulset.metadata.annotations = {}
    statefulset.metadata.annotations["pre-turndown-scaling-configuration"] = str(replicas)
    try:
        logger.debug("Scaling down statefulset " + statefulset.metadata.name + " in namespace " + statefulset.metadata.namespace)
        k8s_apps.patch_namespaced_stateful_set(statefulset.metadata.name, statefulset.metadata.namespace, {"metadata": {"annotations": statefulset.metadata.annotations}})
        k8s_apps.patch_namespaced_stateful_set_scale(statefulset.metadata.name, statefulset.metadata.namespace, {'spec': {'replicas': 0}})
    except ApiException as e:
        logger.info("Failed to patch statefulset " + statefulset.metadata.name + " : " + e)

def scaledown_namespace_statefulsets(namespace):
    """
    Scale down all statefulsets in the specified namespace to 0 replicas.
    Waits for all StatefulSets to scale down and terminate.
    """
    k8s_apps = get_k8s_apps_client()
    try:
        statefulsets = k8s_apps.list_namespaced_stateful_set(namespace)
    except ApiException as e:
        logger.info("Failed to list statefulsets in namespace " + namespace +":"+ e)
        return

    logger.info("Scaling down statefulsets in namespace " + namespace)

    for statefulset in statefulsets.items:
        scaledown_statefulset(statefulset.metadata.name, namespace)

    while True:
        all_scaled_down = True
        try:
            current_sets = k8s_apps.list_namespaced_stateful_set(namespace)
        except ApiException as e:
            logger.info("Error fetching statefulSet status in namespace " + namespace + " : " + e)
            break

        for sts in current_sets.items:
            name = sts.metadata.name
            desired = sts.spec.replicas or 0
            ready = sts.status.ready_replicas or 0
            if ready > 0:
                logger.info("Statefulset " + name + " in namespace " + namespace + " not yet scaled down: " + str(ready) + "/" + str(desired))
                all_scaled_down = False
            else:
                logger.debug("Statefulset " + name + " in namespace " + namespace + " scaled down: " + str(ready) + "/" + str(desired))

        if all_scaled_down:
            logger.info("All statefulSets scaled down successfully in namespace " + namespace)
            break
        sleep(10)


def delete_namespace_strimzipodsets(namespace):
    """
    Delete all StrimziPodSet resources from a given namespace.
    This is required for Kafka Strimzi clusters before scaling down.
    Waits for all StrimziPodSet pods to terminate.
    """
    k8s_crd = get_k8s_crd_client()
    k8s_core = get_k8s_client()

    logger.info("Deleting strimzipodsets in namespace " + namespace)

    # Defining the group, version, and plural for StrimziPodSet
    group = "core.strimzi.io"
    version = "v1beta2"
    plural = "strimzipodsets"
    namespace = namespace

    try:
        podsets = k8s_crd.list_namespaced_custom_object(
            group=group,
            version=version,
            namespace=namespace,
            plural=plural
        )
    except ApiException as e:
        logger.info("Failed to list strimzipodsets in namespace " + namespace + " : " + e)
        return

    for podset in podsets.get("items", []):
        podsetname = podset["metadata"]["name"]

        # Determine label selector to find pods belonging to this PodSet
        # StrimziPodSet typically manages pods using a label like 'strimzi.io/name'
        labels = podset["spec"].get("template", {}).get("metadata", {}).get("labels", {})
        label_selector = ",".join([f"{k}={v}" for k, v in labels.items()]) if labels else f"strimzi.io/name={podsetname}"

        try:
            logger.info("Deleting strimzipodset " + podsetname + " in namespace " + namespace)
            k8s_crd.delete_namespaced_custom_object(
                group=group,
                version=version,
                namespace=namespace,
                plural=plural,
                name=podsetname,
                body=client.V1DeleteOptions()
            )
        except ApiException as e:
            logger.info("Failed to delete strimzipodset " + podsetname + " in namespace " + namespace + " : " + e)

    while True:
        try:
            pods = k8s_core.list_namespaced_pod(
                namespace=namespace,
                label_selector=label_selector
            )
        except ApiException as e:
            logger.info("Error listing pods for strimzipodset " + podsetname + " in namespace " + namespace + " : " + e)
            break

        if not pods.items:
            logger.info("All pods for strimzipodset " + podsetname + " in namespace " + namespace + " have been terminated")
            break
        else:
            pod_names = [p.metadata.name for p in pods.items]
            logger.info("Still waiting on pods from strimzipodset " + podsetname + " in namespace " + namespace + " : " + ", ".join(pod_names))
        sleep(10)

def scaleup_deployment(name, namespace):
    """
    Scale up a single deployment using the saved replica count from annotations.
    """
    k8s_apps = get_k8s_apps_client()
    deployment = k8s_apps.read_namespaced_deployment(name, namespace)
    replicas = (deployment.metadata.annotations or {}).get("pre-turndown-scaling-configuration", "")
    if replicas != "":
        try:
            logger.info("Scaling up deployment " + deployment.metadata.name + " in namespace " + deployment.metadata.namespace)
            k8s_apps.patch_namespaced_deployment_scale(deployment.metadata.name, deployment.metadata.namespace, {'spec': {'replicas': int(replicas)}})
        except ApiException as e:
            logger.info("Failed to patch deployment " + deployment.metadata.name + " in namespace " + deployment.metadata.namespace + " : " + e)

def scaleup_namespace_deployments(namespace):
    """
    Scale up all deployments in the specified namespace using previously
    stored replica counts from annotations. Waits for all Deployments to become ready.
    """
    k8s_apps = get_k8s_apps_client()
    try:
        deployments = k8s_apps.list_namespaced_deployment(namespace)
    except ApiException as e:
        logger.info("Failed to list deployments in namespace " + namespace + " : " + e)
        return

    logger.info("Scaling up deployments in namespace " + namespace)

    # Start scaling up
    for deployment in deployments.items:
        scaleup_deployment(deployment.metadata.name, namespace)

    while True:
        all_ready = True
        try:
            current_deps = k8s_apps.list_namespaced_deployment(namespace)
        except ApiException as e:
            logger.info("Error fetching deployment status in namespace " + namespace + " : " + e)
            break

        for dep in current_deps.items:
            name = dep.metadata.name
            desired = dep.spec.replicas
            ready = dep.status.ready_replicas or 0
            if ready < desired:
                logger.info("Deployment " + name + " in namespace " + namespace + " not yet ready: " + str(ready) + "/" + str(desired))
                all_ready = False
            else:
                logger.debug("Deployment " + name + " in namespace " + namespace + " is ready: " + str(ready) + "/" + str(desired))

        if all_ready:
            logger.info("All deployments are ready in namespace " + namespace)
            break

        sleep(10)

def scaleup_statefulset(name, namespace):
    """
    Scale up a single statefulset using the saved replica count from annotations.
    """
    k8s_apps = get_k8s_apps_client()
    statefulset = k8s_apps.read_namespaced_stateful_set(name, namespace)
    replicas = (statefulset.metadata.annotations or {}).get("pre-turndown-scaling-configuration", "")
    if replicas != "":
        try:
            logger.info("Scaling up statefulset " + statefulset.metadata.name + " in namespace " + statefulset.metadata.namespace)
            k8s_apps.patch_namespaced_stateful_set_scale(statefulset.metadata.name, statefulset.metadata.namespace, {'spec': {'replicas': int(replicas)}})
        except ApiException as e:
            logger.info("Failed to patch statefulset " + statefulset.metadata.name + " in namespace " + statefulset.metadata.namespace + " : " + e)

def scaleup_namespace_statefulsets(namespace):
    """
    Scale up all statefulsets in the specified namespace using previously
    stored replica counts from annotations. Waits for all StatefulSets to become ready.
    """
    k8s_apps = get_k8s_apps_client()
    try:
        statefulsets = k8s_apps.list_namespaced_stateful_set(namespace)
    except ApiException as e:
        logger.info("Failed to list statefulsets in namespace " + namespace + " : " + e)
        return

    logger.info("Scaling up statefulsets in namespace " + namespace)

    # Start scaling up
    for statefulset in statefulsets.items:
        scaleup_statefulset(statefulset.metadata.name, namespace)

    while True:
        all_ready = True
        try:
            current_sets = k8s_apps.list_namespaced_stateful_set(namespace)
        except ApiException as e:
            logger.info("Error fetching statefulset status in namespace " + namespace + " : " + e)
            break

        for sts in current_sets.items:
            name = sts.metadata.name
            desired = sts.spec.replicas
            ready = sts.status.ready_replicas or 0
            if ready < desired:
                logger.info("StatefulSet " + name + " in namespace " + namespace + " not yet ready: " + str(ready) + "/" + str(desired))
                all_ready = False
            else:
                logger.debug("StatefulSet " + name + " in namespace " + namespace + " is ready: " + str(ready) + "/" + str(desired))

        if all_ready:
            logger.info("All statefulsets are ready in namespace " + namespace)
            break

        sleep(10)

def check_pods_ready_in_namespaces(namespaces):
    """
    Waits until all pods in the provided list of namespaces are in 'Running' phase
    and all containers are Ready.
    """
    k8s_core = get_k8s_client()

    while True:
        all_namespaces_ready = True

        for namespace in namespaces:
            logger.info("Checking pods in namespace: " + namespace)
            try:
                pods = k8s_core.list_namespaced_pod(namespace)
            except ApiException as e:
                logger.info("Failed to list pods in namespace " + namespace + " : " + e)
                all_namespaces_ready = False
                continue

            all_pods_ready = True
            for pod in pods.items:
                pod_name = pod.metadata.name
                phase = pod.status.phase
                conditions = pod.status.conditions or []

                ready_condition = next((c for c in conditions if c.type == "Ready"), None)
                is_ready = ready_condition and ready_condition.status == "True"

                # Logic:
                # - If Running: must be Ready
                # - If Succeeded: always considered ready ( K8s Jobs etc. )
                # - Else: not ready
                if (phase == "Running" and not is_ready) or (phase not in ("Running", "Succeeded")):
                    logger.info("Pod " + pod_name + " in namespace " + namespace + " is not ready: Phase " + phase + ", Ready=" + str(is_ready))
                    all_pods_ready = False
                else:
                    logger.debug("Pod " + pod_name + " in namespace " + namespace + " is running and ready.")

            if not all_pods_ready:
                logger.warning("Some pods are not ready in namespace " + namespace)
                all_namespaces_ready = False
            else:
                logger.info("All pods are ready in namespace " + namespace)

        if all_namespaces_ready:
            logger.info("All pods are running and ready in all specified namespaces.")
            break

        logger.info("Waiting 10 seconds before rechecking pods status...")
        sleep(10)


# EKS NODE SCALING FUNCTIONS

def get_scaling_nodegroups_eks(cluster):
    """
    Retrieve all nodegroups for a given EKS cluster,
    excluding any that have the label 'cluster-controller=true'.
    """
    eks_client = boto3.client("eks")
    ng_list = eks_client.list_nodegroups(clusterName=cluster)
    nodegroups = []
    for ng in ng_list["nodegroups"]:
        nodegroup = eks_client.describe_nodegroup(clusterName=cluster, nodegroupName=ng)["nodegroup"]
        if nodegroup.get("labels", {}).get("cluster-controller", {}) == "true":
            continue
        else:
            nodegroups.append(nodegroup)
    return nodegroups

def scaledown_nodegroups_eks(clusterName):
    """
    Scale down all matching EKS nodegroups in a cluster using stored scaling config from tags.
    """
    nodegroups = get_scaling_nodegroups_eks(clusterName)

    monitoring_tasks = []

    with ThreadPoolExecutor(max_workers=len(nodegroups)) as executor:
        for ng in nodegroups:
            result = initiate_scaledown_eks(ng)
            if result:
                # Submit monitoring task to run in background
                future = executor.submit(
                    monitor_scaledown_eks,
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
            logger.info("Monitoring task failed: " + e)
    logger.info("Nodegroup(s) scale-down operations complete!")

def initiate_scaledown_eks(ng):
    """
    Triggers the scale-down of the EKS nodegroup and returns the update ID.
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

def monitor_scaledown_eks(clusterName, nodegroupName, updateId):
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

def scaleup_nodegroups_eks(clusterName):
    """
    Scale up all matching EKS nodegroups in a cluster using stored scaling config from tags.
    """
    nodegroups = get_scaling_nodegroups_eks(clusterName)

    monitoring_tasks = []

    with ThreadPoolExecutor(max_workers=len(nodegroups)) as executor:
        for ng in nodegroups:
            result = initiate_scaleup_eks(ng)
            if result:
                # Submit monitoring task to run in background
                future = executor.submit(
                    monitor_scaleup_eks,
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
            logger.info("Monitoring task failed: " + e)
    logger.info("Nodegroup(s) scaleup operations complete!")

def initiate_scaleup_eks(ng):
    """
    Scale up a single EKS nodegroup based on stored configuration in tags.
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

def monitor_scaleup_eks(clusterName, nodegroupName, updateId):
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