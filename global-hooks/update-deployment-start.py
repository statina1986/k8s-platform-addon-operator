#!/usr/bin/env python3

import sys
import datetime
from common.python.hooks import *
from common.python.k8s import *
from kubernetes.client.rest import ApiException

from common.python.variables import *


class MyHook(Hook):
    def __init__(self):
        super().__init__("""            
configVersion: v1
beforeAll: 1
""")

    def handle_binding(self, binding):
        match(binding):
            case BeforeAllHook():
                k8s_crd = get_k8s_crd_client()

                try:
                    k8s_crd.create_namespaced_custom_object(
                        group="qvantel.com",
                        version="v1",
                        namespace=ADDON_OPERATOR_NAMESPACE,
                        plural="deploymentstatuses",
                        body={
                            "apiVersion": "qvantel.com/v1",
                            "kind": "DeploymentStatus",
                            "metadata": {
                                "name": "platform-deployment"
                            },
                            "spec": {}
                        })
                    k8s_crd.patch_namespaced_custom_object_status(
                        group="qvantel.com",
                        version="v1",
                        name="platform-deployment",
                        namespace=ADDON_OPERATOR_NAMESPACE,
                        plural="deploymentstatuses",
                        body={
                                "status": {
                                    "conditions": [{"type": "Ready", "status": "False", "reason": "ModuleDeploymentStarted"}]
                                }
                        })
                except ApiException as e:
                    if e.status == 409:  # if the CRD already exists the K8s API will respond with a 409 Conflict
                        logger.info("Deployment resource already exist")
                    elif e.status == 404:  # if the CRD does not exist the K8s API will respond with a 404 Conflict
                        logger.info("Deployment resource does not exist, make sure CRDs are deployed first")
                    else:
                        raise e

                update_crd_status(
                    group="qvantel.com",
                    version="v1",
                    name="platform-deployment",
                    namespace=ADDON_OPERATOR_NAMESPACE,
                    plural="deploymentstatuses",
                    update=lambda response: updateCrdStatusCondition(
                        response, "Ready", "False", "ModuleDeploymentStarted")
                )

            case _:
                print("Unknown hook data")
                
hook = MyHook()
hook.handle_hook()
