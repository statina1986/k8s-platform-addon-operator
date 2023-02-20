#!/usr/bin/env python3

import sys
import datetime
from common.python.hooks import *
from common.python.utils import kebab
from common.python.k8s import *
from kubernetes.client.rest import ApiException
from common.python.logger import logger

match(handle_hook()):
    case ConfigHook():
        print(
            """
configVersion: v1
onStartup: 1
afterHelm: 999
""")
    case StartupHook(values, configValues):
        k8s_crd = get_k8s_crd_client()

        moduleName = list(values.keys())[1]

        update_crd_status(group="qvantel.com",
                          version="v1",
                          name="platform-deployment",
                          namespace="platform",
                          plural="deploymentstatuses",
                          update=lambda response: updateCrdStatusCondition(response, moduleName+"-ready", "False", "ModuleDeploymentStarted"))

    case AfterHelmHook(values, configValues):
        k8s_crd = get_k8s_crd_client()

        moduleName = list(values.keys())[1]

        def setModuleDeployed(response):
            count = response['status']['deployedModulesCount']
            count = count + 1
            response = updateCrdStatusCondition(
                response, moduleName+"-ready", "true", "ModuleDeploymentCompleted")
            response['status']['deployedModulesCount'] = count
            return response

        update_crd_status(group="qvantel.com",
                          version="v1",
                          name="platform-deployment",
                          namespace="platform",
                          plural="deploymentstatuses",
                          update=setModuleDeployed)

    case _:
        print("Unknown hook data")
