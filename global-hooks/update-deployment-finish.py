#!/usr/bin/env python3

import sys
import datetime
from common.python.hooks import *
from common.python.k8s import *
from kubernetes.client.rest import ApiException


match(handle_hook()):
    case ConfigHook():
        print(
            """
configVersion: v1
afterAll: 999
""")
    case AfterAllHook():
        k8s_crd = get_k8s_crd_client()

        update_crd_status(
            group="qvantel.com",
            version="v1",
            name="platform-deployment",
            namespace="platform",
            plural="deploymentstatuses",
            update=lambda response: updateCrdStatusCondition(
                response, "Ready", "True", "DeploymentCompleted")
        )

    case _:
        print("Unknown hook data")
