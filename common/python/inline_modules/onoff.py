import json
import yaml
import time
from time import sleep
import boto3
from common.python.vault import *
from common.python.k8s import *
from kubernetes.client.rest import ApiException
from concurrent.futures import ThreadPoolExecutor

# CLUSTER SHUTDOWN / STARTUP

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
    if deployment.metadata.name == "shutdown-addon-operator":
        logger.info("Skipping deployment " + deployment.metadata.name + " in namespace " +  deployment.metadata.namespace + " as it controls the scaling operations")
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

def scaledown_namespace_deployments(namespace, exclude=None):
    """
    Scale down all deployments in the specified namespace to 0 replicas,
    except those in 'exclude'. Waits for all non-excluded deployments to
    scale down and terminate.

    Args:
        namespace (str): The Kubernetes namespace to act on.
        exclude (list[str] or None): Deployment names to skip.
            Example: ['deployment-a', 'deployment-b', 'deployment-c']
    """

    k8s_apps = get_k8s_apps_client()

    exclude = exclude or []

    try:
        deployments = k8s_apps.list_namespaced_deployment(namespace)
    except ApiException as e:
        logger.info("Failed to list deployments in namespace " + namespace + ": " + str(e))
        return
    
    if exclude:
        logger.info(
            "Scaling down deployments in namespace %s (excluding: %s)",
            namespace,
            ", ".join(sorted(exclude))
        )
    else:
        logger.info("Scaling down deployments in namespace %s", namespace)

    for deployment in deployments.items:
        name = deployment.metadata.name
        if name in exclude:
            logger.info(
                "Skipping scale-down for deployment %s in namespace %s (excluded)",
                name, namespace
            )
            continue
        scaledown_deployment(name, namespace)

    while True:
        all_scaled_down = True
        try:
            current_deployments = k8s_apps.list_namespaced_deployment(namespace)
        except ApiException as e:
            logger.info("Error fetching deployment status: " + str(e))
            break

        for deploy in current_deployments.items:
            name = deploy.metadata.name
            if name == "shutdown-addon-operator":
                logger.info("Skipping checking deployment " + name + " in namespace " + namespace + " as it controls the shutdown operations")
                continue
            if name in exclude:
                logger.info(
                    "Skipping checking deployment %s in namespace %s (excluded)",
                    name, namespace
                )
                continue
            desired = deploy.spec.replicas or 0
            ready = deploy.status.ready_replicas or 0
            if ready > 0:
                logger.info("Deployment " + name +  " in namespace " + namespace + " not yet scaled down: " + str(ready) + "/" + str(desired))
                all_scaled_down = False
            else:
                logger.debug("Deployment " + name + " in namespace " + namespace + " scaled down: " + str(ready) + "/" + str(desired))

        if all_scaled_down:
            logger.info("All non-excluded deployments scaled down successfully in namespace " + namespace)
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

def scaledown_namespace_statefulsets(namespace, exclude=None):
    """
    Scale down all statefulsets in the specified namespace to 0 replicas,
    except those in 'exclude'. Waits for all non-excluded statefulsets to
    scale down and terminate.

    Args:
        namespace (str): The Kubernetes namespace to act on.
        exclude (list[str] or None): Statefulsets names to skip.
            Example: ['statefulset-a', 'statefulset-b', 'statefulset-c']
    """
    k8s_apps = get_k8s_apps_client()

    exclude = exclude or []

    try:
        statefulsets = k8s_apps.list_namespaced_stateful_set(namespace)
    except ApiException as e:
        logger.info("Failed to list statefulsets in namespace " + namespace +":"+ e)
        return

    if exclude:
        logger.info(
            "Scaling down statefulsets in namespace %s (excluding: %s)",
            namespace,
            ", ".join(sorted(exclude))
        )
    else:
        logger.info("Scaling down statefulsets in namespace %s", namespace)

    for statefulset in statefulsets.items:
        name = statefulset.metadata.name
        if name in exclude:
            logger.info(
                "Skipping scale-down for statefulset %s in namespace %s (excluded)",
                name, namespace
            )
            continue
        scaledown_statefulset(name, namespace)

    while True:
        all_scaled_down = True
        try:
            current_sets = k8s_apps.list_namespaced_stateful_set(namespace)
        except ApiException as e:
            logger.info("Error fetching statefulset status in namespace " + namespace + " : " + e)
            break

        for sts in current_sets.items:
            name = sts.metadata.name
            desired = sts.spec.replicas or 0
            ready = sts.status.ready_replicas or 0
            if name in exclude:
                logger.info(
                    "Skipping checking statefulset %s in namespace %s (excluded)",
                    name, namespace
                )
                continue
            if ready > 0:
                logger.info("Statefulset " + name + " in namespace " + namespace + " not yet scaled down: " + str(ready) + "/" + str(desired))
                all_scaled_down = False
            else:
                logger.debug("Statefulset " + name + " in namespace " + namespace + " scaled down: " + str(ready) + "/" + str(desired))

        if all_scaled_down:
            logger.info("All statefulsets scaled down successfully in namespace " + namespace)
            break
        sleep(10)

def delete_strimzipodset(name, namespace):
    """
    Delete a single strimzipodset.
    """
    
    # Defining the group, version, and plural for StrimziPodSet
    group = "core.strimzi.io"
    version = "v1beta2"
    plural = "strimzipodsets"

    k8s_crd = get_k8s_crd_client()
    k8s_core = get_k8s_client()

    try:
        podset = k8s_crd.get_namespaced_custom_object(
            group=group,
            version=version,
            namespace=namespace,
            plural=plural,
            name=name
        )
    except ApiException as e:
        logger.info("Failed to list strimzipodset " + name + " in namespace " + namespace + " : " + e)
        return

    # Determine label selector to find pods belonging to this PodSet
    # StrimziPodSet typically manages pods using a label like 'strimzi.io/name'
    labels = podset["spec"].get("template", {}).get("metadata", {}).get("labels", {})
    label_selector = ",".join([f"{k}={v}" for k, v in labels.items()]) if labels else f"strimzi.io/name={name}"

    try:
        logger.info("Deleting strimzipodset " + name + " in namespace " + namespace)
        k8s_crd.delete_namespaced_custom_object(
            group=group,
            version=version,
            namespace=namespace,
            plural=plural,
            name=name,
            body=client.V1DeleteOptions()
        )
    except ApiException as e:
        logger.info("Failed to delete strimzipodset " + name + " in namespace " + namespace + " : " + e)

    while True:
        try:
            pods = k8s_core.list_namespaced_pod(
                namespace=namespace,
                label_selector=label_selector
            )
        except ApiException as e:
            logger.info("Error listing pods for strimzipodset " + name + " in namespace " + namespace + " : " + e)
            break

        if not pods.items:
            logger.info("All pods for strimzipodset " + name + " in namespace " + namespace + " have been terminated")
            break
        else:
            pod_names = [p.metadata.name for p in pods.items]
            logger.info("Still waiting on pods from strimzipodset " + name + " in namespace " + namespace + " : " + ", ".join(pod_names))
        sleep(10)

def delete_namespace_strimzipodsets(namespace, exclude=None):
    """
    Delete all StrimziPodSet resources in the specified namespace,
    except those in 'exclude'. Waits for all non-excluded StrimziPodSet pods to terminate.
    This is required for Kafka Strimzi clusters before scaling down when they are using ZooKeeper.

    Args:
        namespace (str): The Kubernetes namespace to act on.
        exclude (list[str] or None): StrimziPodSet names to skip.
            Example: ['strimzipodset-a', 'strimzipodset-b', 'strimzipodset-c']
    """

    # Defining the group, version, and plural for StrimziPodSet
    group = "core.strimzi.io"
    version = "v1beta2"
    plural = "strimzipodsets"

    k8s_crd = get_k8s_crd_client()
    k8s_core = get_k8s_client()

    exclude = exclude or []

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

    if exclude:
        logger.info(
            "Deleting strimzipodsets in namespace %s (excluding: %s)",
            namespace,
            ", ".join(sorted(exclude))
        )
    else:
        logger.info("Deleting strimzipodsets in namespace %s", namespace)

    for ps in podsets.get("items", []):
        podsetname = ps["metadata"]["name"]
        if podsetname in exclude:
            logger.info(
                "Skipping deletion for strimzipodset %s in namespace %s (excluded)",
                podsetname, namespace
            )
            continue
        delete_strimzipodset(podsetname, namespace)


def monitor_job(batch_api, job_name, namespace, timeout=600, poll_interval=10):
    """Monitor a Kubernetes Job until it succeeds or fails."""
    start_time = time.time()
    while True:
        job_status = batch_api.read_namespaced_job_status(job_name, namespace)
        succeeded = job_status.status.succeeded or 0
        failed = job_status.status.failed or 0

        if succeeded > 0:
            logger.info(f"Job {job_name} succeeded.")
            return True
        if failed > 0:
            logger.info(f"Job {job_name} failed.")
            return False
        if time.time() - start_time > timeout:
            logger.info(f"Timeout waiting for Job {job_name}.")
            return False
        sleep(poll_interval)


def trigger_strimzi_shutdown(namespace, shutdown_command):
    """
    Creates a shutdown Job for each Kafka cluster in the namespace using strimzi-shutdown ( Ref: https://github.com/scholzj/strimzi-shutdown ).
    Waits until each Job succeeds or times out.
    This is required for Kafka Strimzi clusters before scaling down when they are using KRaft, ref: https://github.com/orgs/strimzi/discussions/10082

    Args:
        namespace (str): The Kubernetes namespace to act on.
        shutdown_command (str): 'stop' or 'continue'
    """

    # Defining the group, version, and plural for Kafkas
    group = "kafka.strimzi.io"
    version = "v1beta2"
    plural = "kafkas"

    # API clients
    k8s_crd = get_k8s_crd_client()
    k8s_batch = get_k8s_batch_client()

    try:
        kafka_clusters = k8s_crd.list_namespaced_custom_object(
            group=group,
            version=version,
            namespace=namespace,
            plural=plural
        )
    except ApiException as e:
        logger.info("Failed to list Kafkas in namespace " + namespace +":"+ e)
        return

    monitoring_tasks = []
    
    with ThreadPoolExecutor(max_workers=len(kafka_clusters.get("items", []))) as executor:
        for item in kafka_clusters.get("items", []):
            cluster_name = item["metadata"]["name"]
            
            cm = get_config_map(ADDON_OPERATOR_NAMESPACE, ADDON_OPERATOR_CONFIG_MAP)
            registry_base = yaml.safe_load(cm.data["global"]).get("containerRegistryBase", "ghcr.io")
            image = f"{registry_base}/scholzj/strimzi-shutdown:0.1.0"

            job_name = f"strimzi-shutdown-{cluster_name}"
            job = client.V1Job(
                api_version="batch/v1",
                kind="Job",
                metadata=client.V1ObjectMeta(name=job_name),
                spec=client.V1JobSpec(
                    ttl_seconds_after_finished=30, ## Time after job gets deleted once finished
                    backoff_limit=3, ## Retry limit
                    template=client.V1PodTemplateSpec(
                        spec=client.V1PodSpec(
                            service_account_name="strimzi-shutdown",
                            containers=[
                                client.V1Container(
                                    name="strimzi-shutdown",
                                    image=image,
                                    command=["/strimzi-shutdown", shutdown_command, f"--namespace={namespace}", f"--name={cluster_name}"]
                                )
                            ],
                            restart_policy="OnFailure"
                        )
                    )
                )
            )

            # Create the Job
            response = k8s_batch.create_namespaced_job(namespace=namespace, body=job)
            logger.info(f"Created Job: {response.metadata.name}")

            # Submit monitoring task
            future = executor.submit(monitor_job, k8s_batch, job_name, namespace)
            monitoring_tasks.append(future)

    #Wait for all monitoring tasks to finish
    for task in monitoring_tasks:
        try:
            task.result()
        except Exception as e:
            logger.error(f"Monitoring task failed: {e}")

    logger.info("All Strimzi Jobs completed!")

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

def scaleup_namespace_deployments(namespace, exclude=None):
    """
    Scale up all deployments in the specified namespace using previously
    stored replica counts from annotations, except those in 'exclude'. 
    Waits for all non-excluded deployments to become ready.

    Args:
        namespace (str): The Kubernetes namespace to act on.
        exclude (list[str] or None): Deployment names to skip.
            Example: ['deployment-a', 'deployment-b', 'deployment-c']
    """

    k8s_apps = get_k8s_apps_client()

    exclude = exclude or []

    try:
        deployments = k8s_apps.list_namespaced_deployment(namespace)
    except ApiException as e:
        logger.info("Failed to list deployments in namespace " + namespace + " : " + e)
        return

    if exclude:
        logger.info(
            "Scaling up deployments in namespace %s (excluding: %s)",
            namespace,
            ", ".join(sorted(exclude))
        )
    else:
        logger.info("Scaling up deployments in namespace %s", namespace)

    # Start scaling up
    for deployment in deployments.items:
        name = deployment.metadata.name
        if name in exclude:
            logger.info(
                "Skipping scale-up for deployment %s in namespace %s (excluded)",
                name, namespace
            )
            continue
        scaleup_deployment(name, namespace)

    while True:
        all_ready = True
        try:
            current_deployments = k8s_apps.list_namespaced_deployment(namespace)
        except ApiException as e:
            logger.info("Error fetching deployment status in namespace " + namespace + " : " + e)
            break

        for deploy in current_deployments.items:
            name = deploy.metadata.name
            desired = deploy.spec.replicas
            ready = deploy.status.ready_replicas or 0
            if name == "shutdown-addon-operator":
                logger.info("Skipping checking deployment " + name + " in namespace " + namespace + " as it controls the shutdown operations")
                continue
            if name in exclude:
                logger.info(
                    "Skipping checking deployment %s in namespace %s (excluded)",
                    name, namespace
                )
                continue
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

def scaleup_namespace_statefulsets(namespace, exclude=None):
    """
    Scale up all statefulsets in the specified namespace using previously
    stored replica counts from annotations, except those in 'exclude'.
    Waits for all non-excluded statefulsets to become ready.

    Args:
        namespace (str): The Kubernetes namespace to act on.
        exclude (list[str] or None): Statefulsets names to skip.
            Example: ['statefulset-a', 'statefulset-b', 'statefulset-c']
    """
    k8s_apps = get_k8s_apps_client()

    exclude = exclude or []

    try:
        statefulsets = k8s_apps.list_namespaced_stateful_set(namespace)
    except ApiException as e:
        logger.info("Failed to list statefulsets in namespace " + namespace + " : " + e)
        return

    if exclude:
        logger.info(
            "Scaling up statefulsets in namespace %s (excluding: %s)",
            namespace,
            ", ".join(sorted(exclude))
        )
    else:
        logger.info("Scaling up statefulsets in namespace %s", namespace)

    for statefulset in statefulsets.items:
        name = statefulset.metadata.name
        if name in exclude:
            logger.info(
                "Skipping scale-up for statefulset %s in namespace %s (excluded)",
                name, namespace
            )
            continue
        scaleup_statefulset(name, namespace)

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
            if name in exclude:
                logger.info(
                    "Skipping checking statefulset %s in namespace %s (excluded)",
                    name, namespace
                )
                continue
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

    # Remove scaling config from the tags. This is needed to have a clean state similar to what was before scaledown (and Terraforms should feels better). 
    eks_client.untag_resource(
        resourceArn=ng["nodegroupArn"],
        tagKeys=['pre-turndown-scaling-configuration']        
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