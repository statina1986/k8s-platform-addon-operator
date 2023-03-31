import sys
import os
import json
import time
from common.python.logger import logger
from common.python.k8s import *


def getModuleNameFromValues(values):
    for key in values.keys():
        if key != "global":
            return key


class ConfigHook:
    pass


class StartupHook:
    __match_args__ = ("values", "configValues")

    def __init__(self, values, configValues):
        self.values = values
        self.configValues = configValues


class BeforeAllHook:
    __match_args__ = ("values", "configValues")

    def __init__(self, values, configValues):
        self.values = values
        self.configValues = configValues


class AfterAllHook:
    __match_args__ = ("values", "configValues")

    def __init__(self, values, configValues):
        self.values = values
        self.configValues = configValues


class BeforeHelmHook:
    __match_args__ = ("values", "configValues")

    def __init__(self, values, configValues):
        self.values = values
        self.configValues = configValues


class AfterHelmHook:
    __match_args__ = ("values", "configValues")

    def __init__(self, values, configValues):
        self.values = values
        self.configValues = configValues


class EventHook:
    __match_args__ = ("eventName", "context")

    def __init__(self, eventName, context):
        self.eventName = eventName
        self.context = context


class GroupHook:
    __match_args__ = ("context")

    def __init__(self, context):
        self.context = context


class SynchronizationHook:
    __match_args__ = ("context")

    def __init__(self, context):
        self.context = context


class Hook:

    def __init__(self, config="", retries=5, retryDelay=5):
        self.config = config
        self.retries = retries
        self.retryDelay = retryDelay

    def handle_binding():
        return

    def execute_with_retry(self, binding):
        for i in range(self.retries):
            try:
                self.handle_binding(binding)
            except Exception as e:
                logger.exception("Hook failed with exception")
                time.sleep(self.retryDelay)
            else:            
                break

    def handle_hook(self):

        if len(sys.argv) > 1 and sys.argv[1] == "--config":
            print(self.config)
        else:
            bcp = os.environ['BINDING_CONTEXT_PATH']
            vp = os.environ['VALUES_PATH']
            cvp = os.environ['CONFIG_VALUES_PATH']

            bcp_file = open(bcp)
            bc_json = json.load(bcp_file)
            logger.debug("Binding Context JSON : %s", bc_json)

            vp_file = open(vp)
            values_json = json.load(vp_file)
            logger.debug("Values JSON : %s", values_json)

            cvp_file = open(cvp)
            configValues_json = json.load(cvp_file)
            logger.debug("Config Values JSON : %s", configValues_json)

            for bc in bc_json:
                binding = bc['binding']
                if binding == "onStartup":
                    self.execute_with_retry(StartupHook(
                        values_json, configValues_json))
                elif binding == "afterAll":
                    self.execute_with_retry(AfterAllHook(
                        values_json, configValues_json))
                elif binding == "beforeAll":
                    self.execute_with_retry(BeforeAllHook(
                        values_json, configValues_json))
                elif binding == "afterHelm":
                    self.execute_with_retry(AfterHelmHook(
                        values_json, configValues_json))
                elif binding == "beforeHelm":
                    self.execute_with_retry(BeforeHelmHook(
                        values_json, configValues_json))
                else:
                    type = bc['type']
                    if type == "Synchronization":
                        self.execute_with_retry(SynchronizationHook(bc))
                    elif type == "Event":
                        event_type = bc['watchEvent']
                        self.execute_with_retry(EventHook(event_type, bc))
                    elif type == "Group":
                        self.execute_with_retry(GroupHook(bc))


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
                                  namespace="platform",
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
                                  namespace="platform",
                                  plural="deploymentstatuses",
                                  update=setModuleDeployed)

            case _:
                print("Unknown hook data")
