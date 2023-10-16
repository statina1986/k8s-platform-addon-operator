#!/usr/bin/env python3

import sys
from common.python.hooks import *
from common.python.utils import get_exception_string
from common.python.vault import *
from common.python.inline import *


class KubernetesAuthRoleHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
kubernetes:
- name: "Monitor Vault KubernetesAuthRoles"
  apiVersion: platform-vault.qvantel.com/v1
  kind: KubernetesAuthRole
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: KubernetesAuthRoleQueue
  allowFailure: true
  jqFilter: '.spec'
""")

    def handle_binding(self, binding):
        match(binding):
            case EventHook(eventName, event):

                name = event['object']['metadata']['name']
                namespace = event['object']['metadata']['namespace']
                mount_point = event['object']['spec'].get(
                    'mount_point', 'kubernetes')
                
                vault_client = get_vault_client()

                if eventName == "Deleted":
                    vault_client.auth.kubernetes.delete_role(
                        name=name,
                        mount_point=mount_point)
                else:
                    try:
                        bound_service_account_names = event['object']['metadata']['bound_service_account_names']
                        bound_service_account_namespaces = event['object']['spec']['bound_service_account_namespaces']
                        token_policies = event['object']['spec']['token_policies']
                        additional_params = event['object']['spec'].get(
                            'additional-params', {})
                        token_ttl = event['object']['spec'].get('token_ttl', '0')
                        token_max_ttl = event['object']['spec'].get(
                            'token_max_ttl', '0')

                        vals = get_computed_values(computed_values)

                        bound_service_account_names = replace_computed_values(bound_service_account_names, vals)
                        bound_service_account_namespaces = replace_computed_values(
                            bound_service_account_namespaces, vals)
                        token_policies = replace_computed_values(
                            token_policies, vals)

                        vault_client.auth.kubernetes.create_role(
                            name=name,
                            bound_service_account_names=bound_service_account_names,
                            bound_service_account_namespaces=bound_service_account_namespaces,
                            ttl=token_ttl,
                            max_ttl=token_max_ttl,
                            policies=token_policies,
                            mount_point=mount_point
                            ** additional_params)

                        execute_post_actions(post_actions, vals)

                        update_crd_status(
                            group="platform-vault.qvantel.com",
                            version="v1",
                            name=name,
                            namespace=namespace,
                            plural="kubernetesauthroles",
                            update=lambda response: updateCrdStatusCondition(
                                    response, "Ready", "True", "KubernetesAuthRoleProvisioned")
                        )
                    except:
                        update_crd_status(
                            group="platform-vault.qvantel.com",
                            version="v1",
                            name=name,
                            namespace=namespace,
                            plural="kubernetesauthroles",
                            update=lambda response: updateCrdStatusCondition(
                                response, "Ready", "False", "KubernetesAuthRoleFailed", get_exception_string())
                        )
                        raise
            case _:
                print("Unknown hook data")


hook = KubernetesAuthRoleHook()
hook.handle_hook()


#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  cat <<EOF
configVersion: v1
kubernetes:
- name: "Monitor Vault Kubernetes Auth Rolesr"
  kind: KubernetesAuthRole  
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: KubernetesAuthRoleQueue
EOF
}

hook::trigger() {
  VAULT_ADDR=${VAULT_ADDR-"http://vault-platform.platform.svc.cluster.local:8200"}

  type=$(jq -r '.[0].type' ${BINDING_CONTEXT_PATH})

  if [[ $type == "Synchronization" ]] ; then
    echo "Skipping current items on startup"

  elif [[ $type == "Event" ]] ; then
    event=$(jq -r '.[0].watchEvent' ${BINDING_CONTEXT_PATH})
    name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
    role_name=$(jq -r '.[0].object.spec."role_name" // empty' ${BINDING_CONTEXT_PATH})
    token="$(vault::get_vault_token)"

    if [[ $event == "Deleted" ]] ; then
      curl::delete "--header 'X-Vault-Token: ${token}' '${VAULT_ADDR}/v1/auth/kubernetes/role/${role_name:-$name}'"
    else      
      bound_service_account_names=$(jq -r '.[0].object.spec."bound_service_account_names"|@json' ${BINDING_CONTEXT_PATH})
      bound_service_account_namespaces=$(jq -r '.[0].object.spec."bound_service_account_namespaces"|@json' ${BINDING_CONTEXT_PATH})
      token_ttl=$(jq -r '.[0].object.spec."token_ttl"|@json' ${BINDING_CONTEXT_PATH})
      token_max_ttl=$(jq -r '.[0].object.spec."token_max_ttl"|@json' ${BINDING_CONTEXT_PATH})
      token_policies=$(jq -r '.[0].object.spec."token_policies"|@json' ${BINDING_CONTEXT_PATH})

      curl::post_data "{\"bound_service_account_names\": $bound_service_account_names, \
        \"bound_service_account_namespaces\": $bound_service_account_namespaces, \
        \"token_policies\": $token_policies}" \
          "--header 'X-Vault-Token: ${token}' '${VAULT_ADDR}/v1/auth/kubernetes/role/${role_name:-$name}'" \
          204
    fi
  fi
}

common::run_hook "$@"