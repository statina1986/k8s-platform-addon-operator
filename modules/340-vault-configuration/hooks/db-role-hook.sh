#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  cat <<EOF
configVersion: v1
kubernetes:
- name: "Monitor Vault DbRole"
  kind: DbRole  
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: DbRoleQueue
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
    role_name=$(jq -r '.[0].object.spec."role-name" // empty' ${BINDING_CONTEXT_PATH})
    token="$(vault::get_vault_token)"

    if [[ $event == "Deleted" ]] ; then
      curl::delete "--header 'X-Vault-Token: ${token}' '${VAULT_ADDR}/v1/database/roles/${role_name:-$name}'"
    else
      db_name=$(jq -r '.[0].object.spec."db-name"|@json' ${BINDING_CONTEXT_PATH})
      max_ttl=$(jq -r '.[0].object.spec."max-ttl"|@json' ${BINDING_CONTEXT_PATH})
      default_ttl=$(jq -r '.[0].object.spec."default-ttl"|@json' ${BINDING_CONTEXT_PATH})
      creation_statements=$(jq -r '.[0].object.spec."creation-statements"|@json' ${BINDING_CONTEXT_PATH})

      curl::post_data "{\"db_name\": $db_name, \
          \"creation_statements\":$creation_statements, \
          \"default_ttl\": $default_ttl, \
          \"max_ttl\": $max_ttl}" \
          "--header 'X-Vault-Token: ${token}' '${VAULT_ADDR}/v1/database/roles/${role_name:-$name}'" \
          204
    fi
  fi
}

common::run_hook "$@"