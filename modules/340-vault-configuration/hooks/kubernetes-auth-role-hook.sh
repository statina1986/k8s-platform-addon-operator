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