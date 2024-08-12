#!/usr/bin/env python3

from common.python.hooks import *
from common.python.k8s import *
from common.python.variables import *

class UpdateModuleDeploymentProgress(Hook):
    def __init__(self):
        super().__init__("""            
configVersion: v1
onStartup: 1
afterHelm: 999
""")

    def handle_binding(self, binding):
        match(binding):
            case StartupHook(values, configValues):
                moduleName = getModuleNameFromValues(values)

                update_crd_status(group="qvantel.com",
                                  version="v1",
                                  name="platform-deployment",
                                  namespace=ADDON_OPERATOR_NAMESPACE,
                                  plural="deploymentstatuses",
                                  update=lambda response: updateCrdStatusCondition(response, moduleName+"-ready", "False", "ModuleDeploymentStarted"))

            case AfterHelmHook(values, configValues):
                moduleName = getModuleNameFromValues(values)

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
                                  namespace=ADDON_OPERATOR_NAMESPACE,
                                  plural="deploymentstatuses",
                                  update=setModuleDeployed)

            case _:
                print("Unknown hook data")

hook = UpdateModuleDeploymentProgress()
hook.handle_hook()


