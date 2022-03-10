#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  cat <<EOF
{
  "configVersion":"v1",
  "kubernetes":[{
    "name": "Monitor Vault Roles",
    "kind": "VaultDbRole",
    "executeHookOnEvent":["Added","Modified","Deleted"]
  }]
}
EOF
}

hook::trigger() {
  type=$(jq -r '.[0].type' ${BINDING_CONTEXT_PATH})

  if [[ $type == "Synchronization" ]] ; then
    echo "Skipping current items on startup"

  elif [[ $type == "Event" ]] ; then
    event=$(jq -r '.[0].watchEvent' ${BINDING_CONTEXT_PATH})

    if [[ $event == "Deleted" ]] ; then
      name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
      role_name=$(jq -r '.[0].object.spec."role-name"' ${BINDING_CONTEXT_PATH}) 
      token="$(vault::get_vault_token)"

      kubectl exec -n platform vault-0 -- /bin/sh -c "vault login -no-print $token && \
        vault delete database/roles/$role_name"

    else
      name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
      role_name=$(jq -r '.[0].object.spec."role-name"' ${BINDING_CONTEXT_PATH}) 
      db_name=$(jq -r '.[0].object.spec."db-name"' ${BINDING_CONTEXT_PATH})
      max_ttl=$(jq -r '.[0].object.spec."max-ttl"' ${BINDING_CONTEXT_PATH})
      default_ttl=$(jq -r '.[0].object.spec."default-ttl"' ${BINDING_CONTEXT_PATH})
      creation_statement=$(jq -r '.[0].object.spec."creation-statement"' ${BINDING_CONTEXT_PATH})

      token="$(vault::get_vault_token)"

      kubectl exec -n platform vault-0 -- /bin/sh -c "vault login -no-print $token && \
        vault write database/roles/$role_name \
          db_name=$db_name \
          creation_statements=\"$creation_statement\" \
          default_ttl=$default_ttl \
          max_ttl=$max_ttl"
    fi
  fi
}

common::run_hook "$@"