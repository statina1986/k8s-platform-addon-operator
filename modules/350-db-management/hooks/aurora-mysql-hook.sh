#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  cat <<EOF
configVersion: v1
kubernetes:
- name: "Monitor AuroraMysql"
  kind: AuroraMysql  
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: AuroraMysqlQueue
EOF
}

hook::trigger() {
  CURL_OPT="-k --connect-timeout 10"
  CURL_RESULT="curl.result"

  type=$(jq -r '.[0].type' ${BINDING_CONTEXT_PATH})

  if [[ $type == "Synchronization" ]] ; then
    qlog "Skipping current items on startup"

  elif [[ $type == "Event" ]] ; then
    event=$(jq -r '.[0].watchEvent' ${BINDING_CONTEXT_PATH})

    if [[ $event == "Deleted" ]] ; then
      name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
      curl::delete "'${VAULT_ADDR}/v1/database/config/$name'"

    else
      name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
      endpoint=$(jq -r '.[0].object.spec."endpoint"' ${BINDING_CONTEXT_PATH})
      credentials_secret=$(jq -r '.[0].object.spec."credentials_secret"' ${BINDING_CONTEXT_PATH})
      username="$(kubectl::get_secret_opaque_kv $credentials_secret 'username' 'platform')"
      password="$(kubectl::get_secret_opaque_kv $credentials_secret 'password' 'platform')"

      token="$(vault::get_vault_token)"
      
      curl::execute "--request POST \
        --header 'X-Vault-Token: ${token}' \
        --data '{\"plugin_name\": \"mysql-aurora-database-plugin\", \
          \"connection_url\":\"{{username}}:{{password}}@tcp($endpoint:3306)/\", \
          \"allowed_roles\":\"*\", \
          \"username\": \"$username\", \
          \"password\": \"$password\"}' \
        '${VAULT_ADDR}/v1/database/config/$name'" 200
    fi
  fi
}

common::run_hook "$@"