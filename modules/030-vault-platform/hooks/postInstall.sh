#!/usr/bin/env bash
set -e

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  CURL_OPT="-sk --connect-timeout 10"
  VAULT_ADDR="http://vault-platform.vault.svc.cluster.local:8200"
  CURL_RESULT="curl.result"

  qlog "Waiting for vault-platform-0 to become ready"
  kubectl wait --for=condition=ready --timeout=300s pods/vault-platform-0 -n vault
  token="$(vault::get_vault_token)"
  
  qlog "Ensuring kubernetes auth enabled"
  STATUS="$(curl ${CURL_OPT} -w '%{http_code}' -o ${CURL_RESULT} --header "X-Vault-Token: ${token}"  ${VAULT_ADDR}/v1/sys/auth)"
  if [ ! "$(jq 'has("kubernetes/")' ${CURL_RESULT})" == "true" ]; then
    kubectl exec -n vault vault-platform-0 -- /bin/sh -c "vault login -no-print $token && \
        vault auth enable kubernetes && \
        vault write auth/kubernetes/config \        
            kubernetes_host='http://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}'"
    # STATUS="$(curl ${CURL_OPT} -w '%{http_code}' --request POST -o ${CURL_RESULT} --header "X-Vault-Token: ${token}"  ${VAULT_ADDR}/v1/sys/auth)"
  fi

  qlog "Ensuring kubernetes auth configured"
  kubectl exec -n vault vault-platform-0 -- /bin/sh -c "vault write auth/kubernetes/config kubernetes_host='https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}'"
}

common::run_hook "$@"