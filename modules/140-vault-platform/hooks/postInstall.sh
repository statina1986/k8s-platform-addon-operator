#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  VAULT_ADDR="http://vault-platform.platform.svc.cluster.local:8200"

  qlog "Waiting for vault-platform-0 to become ready"
  kubectl wait --for=condition=ready --timeout=300s pods/vault-platform-0 -n platform
  token="$(vault::get_vault_token)"

  qlog "Ensuring kubernetes auth enabled"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/auth'" 200
  if [ ! "$(jq 'has("kubernetes/")' $CURL_RESULT)" == "true" ]; then
    kubectl exec -n platform vault-platform-0 -- /bin/sh -c "vault login -no-print $token && \
        vault auth enable kubernetes && \
        vault write auth/kubernetes/config kubernetes_host='https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT'"
  else
    qlog "Kubernetes auth already enabled"
  fi

  qlog "Ensuring kv secrets engine enabled"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/mounts'" 200
  if [ ! "$(jq 'has("secret/")' $CURL_RESULT)" == "true" ]; then
    kubectl exec -n platform vault-platform-0 -- /bin/sh -c "vault login -no-print $token && \
        vault secrets enable -path='secret' kv"
  else
    qlog "KV Secrets already enabled"
  fi

  qlog "Ensuring database secrets engine enabled"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/mounts'" 200
  if [ ! "$(jq 'has("database/")' $CURL_RESULT)" == "true" ]; then
    kubectl exec -n platform vault-platform-0 -- /bin/sh -c "vault login -no-print $token && \
        vault secrets enable -path='database' database"
  else
    qlog "Database secrets already enabled"
  fi

  qlog "Checking audit logging"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/audit'" 200
  if [ ! "$(jq 'has("file/")' $CURL_RESULT)" == "true" ]
  then
    kubectl exec -n platform vault-platform-0 -- /bin/sh -c "vault login -no-print $token && \
      vault audit enable file file_path=stdout"
    qlog "Audit logging enabled"
  else
    qlog "Audit logging already enabled"
  fi
}

common::run_hook "$@"

