import sys
import os
import json


class ConfigHook:
    pass


class StartupHook:
    pass


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
        file = open(bcp)
        bcp_json = json.load(file)
        binding = bcp_json[0]['binding']
        type = bcp_json[0]['type']
        if binding == "onStartup":
            return StartupHook()
        elif type == "Synchronization":
            return SynchronizationHook(bcp_json)
        elif type == "Event":
            event_type = bcp_json[0]['watchEvent']
            return EventHook(event_type, bcp_json)
