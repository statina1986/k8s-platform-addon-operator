#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  cat <<EOF
{
  "configVersion":"v1",
  "kubernetes":[{
    "name": "Monitor Vault DB Roles",
    "kind": "DbRole",
    "executeHookOnEvent":["Added","Modified","Deleted"]
  }]
}
EOF
}

hook::trigger() {
  VAULT_ADDR=${VAULT_ADDR-"http://vault-platform.platform.svc.cluster.local:8200"}

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
      db_name=$(jq -r '.[0].object.spec."db-name"|@json' ${BINDING_CONTEXT_PATH})
      max_ttl=$(jq -r '.[0].object.spec."max-ttl"|@json' ${BINDING_CONTEXT_PATH})
      default_ttl=$(jq -r '.[0].object.spec."default-ttl"|@json' ${BINDING_CONTEXT_PATH})
      creation_statements=$(jq -r '.[0].object.spec."creation-statements"|@json' ${BINDING_CONTEXT_PATH})

      token="$(vault::get_vault_token)"

      curl::post_data "{\"db_name\": $db_name, \
          \"creation_statements\":$creation_statements, \
          \"default_ttl\": $default_ttl, \
          \"max_ttl\": $max_ttl}" \
          "--header 'X-Vault-Token: ${token}' '${VAULT_ADDR}/v1/database/roles/$name'" \
          204
    fi
  fi
}

common::run_hook "$@"