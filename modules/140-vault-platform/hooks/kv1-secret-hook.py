#!/usr/bin/env python3

import sys
from kubernetes import client, config
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
import hvac

config.load_incluster_config()
v1 = client.CoreV1Api()


class Kv1SecretsHook(Hook):
    def __init__(self):
        vaultPlatform = self.get_addon_operator_config("vaultPlatform")
        super().__init__(str(
            {
                "configVersion": "v1",
                "schedule": [
                    {
                        "name": "kv1secrets-periodic-checking",
                        "crontab": vaultPlatform.get("vaultCrdSync", {}).get("schedule", "*/5 * * * *"),
                        "includeSnapshotsFrom": ["monitor-vault-kv1secrets"]
                    }
                ],
                "kubernetes": [
                    {
                        "name": "monitor-vault-kv1secrets",
                        "apiVersion": "platform-vault.qvantel.com/v1",
                        "kind": "KV1Secret",
                        "executeHookOnEvent": ["Added", "Modified", "Deleted"],
                        "queue": "VaultKV1SecretQueue",
                        # "namespace": vaultPlatform.get("vaultCrdSync", {}).get("namespaceSelector", {
                        #     "labelSelector": {
                        #         "matchLabels": {
                        #             "platform.qvantel.com/vault-crd-sync": "true"
                        #         }
                        #     }
                        # }),
                        "allowFailure": True,
                        "jqFilter": '.spec'
                    }
                ]
            })
        )

    def registerResource(self, event, vault_client):
        try:
            name = event['object']['metadata']['name']
            namespace = event['object']['metadata']['namespace']
            vault_client = get_vault_client()
            path = event['object']['spec']['path']
            # compatibility with qdeployer 3.80.0
            if path.startswith("secret/"):
                path = path.replace("secret/", "", 1)

            values = event['object']['spec']['secret']
            # Merge data from CRD with existing values. Existing values takes priority.
            try:
                existing = vault_client.secrets.kv.v1.read_secret(path)['data']
                values = {**values, **existing}
            except:
                pass
            vault_client.secrets.kv.v1.create_or_update_secret(path, secret=values)

            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="kv1secrets",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "True", "KV1SecretProvisioned")
            )
        except:
            update_crd_status(
                group="platform-vault.qvantel.com",
                version="v1",
                name=name,
                namespace=namespace,
                plural="kv1secrets",
                update=lambda response: updateCrdStatusCondition(
                    response, "Ready", "False", "KV1SecretFailed", get_exception_string())
            )
            raise

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event):
                if eventName == "Deleted":
                    # vault_client.secrets.kv.v1.delete_secret(path)
                    return
                else:
                    self.registerResource(event, vault_client)
                    
            case ScheduleHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping Vault CRD sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('snapshots', {}).get('monitor-vault-kv1secrets', []):
                    self.registerResource(event, vault_client)

            case SynchronizationHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('enabled', 'false') == 'false':
                    print("Skipping Vault CRD sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('objects', []):
                    self.registerResource(event, vault_client)
            case _:
                print("Unknown hook data")


hook = Kv1SecretsHook()
hook.handle_hook()
