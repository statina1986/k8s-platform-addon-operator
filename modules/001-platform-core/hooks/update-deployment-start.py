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
onStartup: 1
""")

    def handle_binding(self, binding):
        match(binding):
            case StartupHook(values, configValues):
                count = values['global']['enabledModules']

                def updateModulesCount(response):
                    response['status']['enabledModulesCount'] = len(count)
                    response['status']['deployedModulesCount'] = 0
                    return response

                update_crd_status(
                    group="qvantel.com",
                    version="v1",
                    name="platform-deployment",
                    namespace=ADDON_OPERATOR_NAMESPACE,
                    plural="deploymentstatuses",
                    update=updateModulesCount)

            case _:
                print("Unknown hook data")


hook = MyHook()
hook.handle_hook()
