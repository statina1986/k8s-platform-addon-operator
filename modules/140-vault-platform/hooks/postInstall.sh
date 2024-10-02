#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"
source "${0%/*}/../../../common/shell/variables.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  
  qlog "Waiting for $VAULT_RELEASE_NAME-0 to become ready"
  kubectl wait --for=condition=ready --timeout=300s pods/$VAULT_RELEASE_NAME-0 -n $ADDON_OPERATOR_NAMESPACE
  token="$(vault::get_vault_token)"

  qlog "Ensuring kubernetes auth enabled"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/auth'" 200
  if [ ! "$(jq 'has("kubernetes/")' $CURL_RESULT)" == "true" ]; then
    kubectl exec -n $ADDON_OPERATOR_NAMESPACE $VAULT_RELEASE_NAME-0 -- /bin/sh -c "vault login -no-print $token && \
        vault auth enable kubernetes && \
        vault write auth/kubernetes/config kubernetes_host='https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT'"
  else
    qlog "Kubernetes auth already enabled"
  fi

  qlog "Ensuring kv secrets engine enabled"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/mounts'" 200
  if [ ! "$(jq 'has("secret/")' $CURL_RESULT)" == "true" ]; then
    kubectl exec -n $ADDON_OPERATOR_NAMESPACE $VAULT_RELEASE_NAME-0 -- /bin/sh -c "vault login -no-print $token && \
        vault secrets enable -path='secret' kv"
  else
    qlog "KV Secrets already enabled"
  fi

  qlog "Ensuring database secrets engine enabled"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/mounts'" 200
  if [ ! "$(jq 'has("database/")' $CURL_RESULT)" == "true" ]; then
    kubectl exec -n $ADDON_OPERATOR_NAMESPACE $VAULT_RELEASE_NAME-0 -- /bin/sh -c "vault login -no-print $token && \
        vault secrets enable -path='database' database"
  else
    qlog "Database secrets already enabled"
  fi

  qlog "Checking audit logging"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/audit'" 200
  if [ ! "$(jq 'has("file/")' $CURL_RESULT)" == "true" ]
  then
    kubectl exec -n $ADDON_OPERATOR_NAMESPACE $VAULT_RELEASE_NAME-0 -- /bin/sh -c "vault login -no-print $token && \
      vault audit enable file file_path=stdout"
    qlog "Audit logging enabled"
  else
    qlog "Audit logging already enabled"
  fi
}

common::run_hook "$@"

