#!/usr/bin/env python3

import sys
import datetime
from common.python.hooks import *
from common.python.k8s import *
from kubernetes.client.rest import ApiException


def setDeploymentStatus(response, status, reason):
    conditions = response['status']['conditions']
    for idx, item in enumerate(conditions):
        if item["type"] == "Ready":
            conditions.pop(idx)
            break
    conditions.append({
        "lastTransitionTime": datetime.datetime.utcnow().astimezone().isoformat(),
        "status": status,
        "type": "Ready",
        "reason": reason
    })
    return response


match(handle_hook()):
    case ConfigHook():
        print(
            """
configVersion: v1
beforeAll: 1
""")
    case BeforeAllHook():
        k8s_crd = get_k8s_crd_client()

        try:
            k8s_crd.create_namespaced_custom_object(
                group="qvantel.com",
                version="v1",
                namespace="platform",
                plural="deploymentstatuses",
                body={
                    "apiVersion": "qvantel.com/v1",
                    "kind": "DeploymentStatus",
                    "metadata": {
                        "name": "platform-deployment"
                    },
                    "spec": {}
                })
        except ApiException as e:
            if e.status == 409:  # if the CRD already exists the K8s API will respond with a 409 Conflict
                logger.info("Deployment resource already exist")
            else:
                raise e

        update_crd_status(
            group="qvantel.com",
            version="v1",
            name="platform-deployment",
            namespace="platform",
            plural="deploymentstatuses",
            update=lambda response: updateCrdStatusCondition(
                response, "Ready", "False", "ModuleDeploymentStarted")
        )

    case _:
        print("Unknown hook data")
