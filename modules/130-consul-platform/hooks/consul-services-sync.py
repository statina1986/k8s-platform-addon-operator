#!/usr/bin/env python3

import sys

import yaml
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.consul import *
from common.python.inline import *


class ConsulServiceSyncHook(Hook):
    def __init__(self):
        consulPlatform = self.get_addon_operator_config("consulPlatform")
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "consul-sync-periodic-checking",
                        "crontab": consulPlatform.get("serviceSyncForClusterIP", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-clusterIP-services"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-clusterIP-services",
                        "apiVersion": "v1",
                        "kind": "Service",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "namespace": consulPlatform.get("serviceSyncForClusterIP", {}).get("namespaceSelector", {
                            "labelSelector": {
                                "matchLabels": {
                                    "platform.qvantel.com/clusterip-service-consul-sync": "true"
                                }
                            }
                        }),
                        "allowFailure": True
                    }
                ]
            })
        )

    def registerService(self, event, consul_client, prefix=""):
        if event['object']['spec'].get('type', '') != 'ClusterIP':
            return
        name = event['object']['metadata']['name']
        namespace = event['object']['metadata']['namespace']
        id = name+'.'+namespace+".svc"
        address = event['object']['spec'].get('clusterIP', "None")

        if address != "None":
            service_port_annotation = event['object']['metadata'].get('annotations', {}).get('platform.qvantel.com/consul-service-port', "")
            if (service_port_annotation != ""):
                port = int(service_port_annotation)
            else:
                ports = event['object']['spec'].get('ports', [{'port': 8080}])
                port = ports[0].get('port', 8080)
            service = {
                "Service": name,
                "ID": id,
                "Tags": [
                    "k8s"
                ],
                "Port": port,
                "Address": address
            }
            check = {
                "Node": "addon-operator-consul-sync",
                "CheckID": namespace+"/"+name,
                "Name": "Kubernetes Readiness Check",
                "Notes": "",
                "Status": "passing",
                "ServiceID": id,
                "Type": "kubernetes-readiness",
                "Interval": "",
                "Timeout": "",
                "ExposedPort": 0,
                "Definition": {}
            }
            consul_client.catalog.register('addon-operator-consul-sync', address, service=service, check=check)

    def handle_binding(self, binding):

        match(binding):
            case EventHook(eventName, event, values):
                if values['consulPlatform'].get('serviceSyncForClusterIP', {}).get('enabled', 'false') == 'false':
                    print("Skipping ClusterIP Service sync as it is disabled in configuration")
                    return

                if event['object']['spec'].get('type', '') != 'ClusterIP':
                    return

                name = event['object']['metadata']['name']
                namespace = event['object']['metadata']['namespace']
                id = name+'.'+namespace+".svc"
                address = event['object']['spec'].get('clusterIP', "None")

                consul_client = get_consul_client()
                if address != "None":
                    if eventName == "Deleted":
                        consul_client.catalog.deregister('addon-operator-consul-sync', service_id=id)
                        return
                    else:
                        prefix = values['consulPlatform'].get('serviceSyncForClusterIP', {}).get('prefix', "")
                        self.registerService(event, consul_client, prefix)

            case ScheduleHook(binding, values):
                if values['consulPlatform'].get('serviceSyncForClusterIP', {}).get('enabled', 'false') == 'false':
                    print("Skipping ClusterIP Service sync as it is disabled in configuration")
                    return

                consul_client = get_consul_client()

                if values['consulPlatform'].get('serviceSyncForClusterIP', {}).get('purgeHashicorpConsulSyncServicesOnStartup', 'false') == 'true':
                    consul_client.catalog.deregister('k8s-sync')

                if values['consulPlatform'].get('serviceSyncForClusterIP', {}).get('purgeClusterIPConsulSyncServicesOnStartup', 'false') == 'true':
                    consul_client.catalog.deregister('addon-operator-consul-sync')

                prefix = values['consulPlatform'].get('serviceSyncForClusterIP', {}).get('prefix', "")

                for event in binding.get('snapshots', {}).get('monitor-clusterIP-services', []):
                    self.registerService(event, consul_client, prefix)

            case SynchronizationHook(binding, values):
                if values['consulPlatform'].get('serviceSyncForClusterIP', {}).get('enabled', 'false') == 'false':
                    print("Skipping ClusterIP Service sync as it is disabled in configuration")
                    return

                prefix = values['consulPlatform'].get('serviceSyncForClusterIP', {}).get('prefix', "")

                for event in binding.get('objects', []):
                    self.registerService(event, get_consul_client(), prefix)
            case _:
                print("Unknown hook data")


hook = ConsulServiceSyncHook()
hook.handle_hook()
