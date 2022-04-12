#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  cat <<EOF
configVersion: v1
kubernetes:
- name: "Monitor Vault Kubernetes Auth Rolesr"
  kind: KubernetesAuthRole  
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
EOF
}

hook::trigger() {
  CURL_OPT="-ks --connect-timeout 10"
  VAULT_ADDR="http://vault-platform.platform.svc.cluster.local:8200"
  CURL_RESULT="curl.result"

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
        vault delete auth/kubernetes/roles/$role_name"

    else
      name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
      bound_service_account_names=$(jq -r '.[0].object.spec."bound_service_account_names"' ${BINDING_CONTEXT_PATH})
      bound_service_account_namespaces=$(jq -r '.[0].object.spec."bound_service_account_namespaces"' ${BINDING_CONTEXT_PATH})
      token_ttl=$(jq -r '.[0].object.spec."token_ttl"' ${BINDING_CONTEXT_PATH})
      token_max_ttl=$(jq -r '.[0].object.spec."token_max_ttl"' ${BINDING_CONTEXT_PATH})
      token_policies=$(jq -r '.[0].object.spec."token_policies"' ${BINDING_CONTEXT_PATH})

      token="$(vault::get_vault_token)"

      # STATUS="$(curl ${CURL_OPT} -w '%{http_code}' -o ${CURL_RESULT} \
      #   --request POST \
      #   --header "X-Vault-Token: ${token}" \
      #   --data \"{\"bound_service_account_names\": $bound_service_account_names, \"bound_service_account_namespaces\": "$bound_service_account_namespaces", \"token_policies\": "$token_policies"}\" \
      #   '${VAULT_ADDR}/auth/kubernetes/role/$name')"
      STATUS=$(curl ${CURL_OPT} -w '%{http_code}' -o ${CURL_RESULT} \
        --request POST \
        --header "X-Vault-Token: ${token}" \
        --data "{\"bound_service_account_names\": $bound_service_account_names, \"bound_service_account_namespaces\": $bound_service_account_namespaces, \"token_policies\": $token_policies}" \
        ${VAULT_ADDR}/v1/auth/kubernetes/role/$name)
    fi
  fi
}

common::run_hook "$@"