import sys
import os
import json
from common.python.logger import logger

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


class SynchronizationHook:
    def __init__(self, context):
        self.context = context


def handle_hook():
    if len(sys.argv) > 1 and sys.argv[1] == "--config":
        return ConfigHook()
    else:
        bcp = os.environ['BINDING_CONTEXT_PATH']
        vp = os.environ['VALUES_PATH']
        cvp = os.environ['CONFIG_VALUES_PATH']

        bcp_file = open(bcp)
        bc_json = json.load(bcp_file)
        logger.debug("Binding Context JSON : %s",bc_json)

        vp_file = open(vp)
        values_json = json.load(vp_file)
        logger.debug("Values JSON : %s",values_json)

        cvp_file = open(cvp)
        configValues_json = json.load(cvp_file)
        logger.debug("Config Values JSON : %s", configValues_json)

        binding = bc_json[0]['binding']
        if binding == "onStartup":
            return StartupHook(values_json, configValues_json)
        elif binding == "afterAll":
            return AfterAllHook(values_json, configValues_json)
        elif binding == "beforeAll":
            return BeforeAllHook(values_json, configValues_json)
        elif binding == "afterHelm":
            return AfterHelmHook(values_json, configValues_json)
        elif binding == "beforeHelm":
            return BeforeHelmHook(values_json, configValues_json)
        else:
            type = bc_json[0]['type']
            if type == "Synchronization":
                return SynchronizationHook(bc_json)
            elif type == "Event":
                event_type = bc_json[0]['watchEvent']
                return EventHook(event_type, bc_json)
