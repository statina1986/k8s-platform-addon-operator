#!/usr/bin/env python3

import sys
from kubernetes import client, config
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
import hvac
from hvac.exceptions import InvalidPath, Forbidden, VaultError

config.load_incluster_config()
v1 = client.CoreV1Api()


class Kv1SecretsHook(Hook):
    def __init__(self):
        vaultPlatform = self.get_addon_operator_config("vaultPlatform")
        platformNamespace = self.get_addon_operator_config('global').get('platformNamespace','platform')
        appsNamespace = self.get_addon_operator_config('global').get('appsNamespace','qvantel') ## We want to sync KV1 secrets from apps namespace also
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
                        "namespace": vaultPlatform.get("vaultCrdSync", {}).get("syncKV1Secrets", {}).get("namespaceSelector", {
                            "nameSelector": {
                                "matchNames": [ appsNamespace, platformNamespace ]
                            }
                        }),
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

            # Strict read: ignore only "not found"
            try:
                resp = vault_client.secrets.kv.v1.read_secret(path=path)  # default mount_point='secret'
                existing = resp.get('data', {}) or {}
            except InvalidPath:
                existing = {}
            except Forbidden as e:
                raise RuntimeError(f"Vault read forbidden for KV1 path 'secret/{path}': {e}") from e
            except VaultError as e:
                raise RuntimeError(f"Vault read failed for KV1 path 'secret/{path}': {e}") from e

            # Existing wins (preserve GUI edits)
            merged = {**values, **existing}

            # Diff guard
            if merged != existing:
                vault_client.secrets.kv.v1.create_or_update_secret(path=path, secret=merged)
                logger.debug("[KV1Secret] Updated secret/" + path + " (applied merged values).")
            else:
                logger.debug("[KV1Secret] No change for secret/" + path + " (skipping write).")


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

    def checkIfReady(self, event):
        conditions = event['object'].get('status', {}).get('conditions', [])
        for idx, item in enumerate(conditions):
            if ((item["type"] == "Ready") and (item["status"] == "True")):
                return True
        return False

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncKV1Secrets', {}).get('enabled') in ('false', False):
                    print("Skipping Vault KV1 Secrets sync as it is disabled in configuration")
                    return
                
                vault_client = get_vault_client()

                if eventName == "Deleted":
                    # Intentionally not deleting from Vault
                    return
                else:
                    self.registerResource(event, vault_client)
                    
            case ScheduleHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncKV1Secrets', {}).get('enabled') in ('false', False):
                    print("Skipping Vault KV1 Secrets sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('snapshots', {}).get('monitor-vault-kv1secrets', []):
                    # Skipping 'Ready' resources from scheduled execution as those were already applied
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping KV1Secret " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.registerResource(event, vault_client)

            case SynchronizationHook(binding, values):
                if values['vaultPlatform'].get('vaultCrdSync', {}).get('syncKV1Secrets', {}).get('enabled') in ('false', False):
                    print("Skipping Vault KV1 Secrets sync as it is disabled in configuration")
                    return

                vault_client = get_vault_client()

                for event in binding.get('objects', []):
                    if self.checkIfReady(event):
                        name = event['object']['metadata']['name']
                        logger.debug("Skipping KV1Secret " + name + " scheduled execution because it is already 'Ready'.")
                    else:
                        self.registerResource(event, vault_client)
            case _:
                print("Unknown hook data")


hook = Kv1SecretsHook()
hook.handle_hook()
