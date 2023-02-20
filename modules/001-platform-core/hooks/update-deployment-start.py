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
onStartup: 1
""")
    case StartupHook(values, configValues):
        k8s_crd = get_k8s_crd_client()

        count = values['global']['enabledModules']

        def updateModulesCount(response):
            response['status']['enabledModulesCount'] = len(count)
            response['status']['deployedModulesCount'] = 0
            return response

        update_crd_status(
            group="qvantel.com",
            version="v1",
            name="platform-deployment",
            namespace="platform",
            plural="deploymentstatuses",
            update=updateModulesCount)

    case _:
        print("Unknown hook data")
