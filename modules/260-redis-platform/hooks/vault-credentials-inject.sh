#!/usr/bin/env bash

# push Redis admin credentials to platform Vault

source "${0%/*}/../../../common/shell/functions.sh"
source "${0%/*}/../../../common/shell/variables.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {

  if ! common::module_is_enabled "vault-platform"; then
    qlog "Vault is not enabled, skipping admin credentials hook"
    exit 0
  fi
  
  qlog "Inserting Redis credentials to legacy kv1 Vault"
  token="$(vault::get_vault_token)"
  FULL_RELEASE_NAME="${HELM_RELEASE_NAME_PREFIX}redis-platform"
  password="$(kubectl::get_secret_opaque_kv $FULL_RELEASE_NAME redis-password $VAULT_SECRET_NAMESPACE)"
  credentials_old=`mktemp`
  credentials_add=`mktemp`
  credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/admin/redis'" '200|404'
  jq -r .data $CURL_RESULT > $credentials_old
  echo '{"redis-password":"'"$password"'"}' > $credentials_add
  jq -s add $credentials_old $credentials_add > $credentials_new
  curl::execute "-d @$credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/admin/redis'" 204
  rm -f $credentials_old $credentials_add $credentials_new

  qlog "Inserting Redis credentials to platform-secret kv2 Vault"
  credentials_old=`mktemp`
  credentials_add=`mktemp`
  credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/redis'" '200|404'
  jq -r .data $CURL_RESULT > $credentials_old
  echo '{"data": {"redis-password":"'"$password"'"}}' > $credentials_add
  jq -s add $credentials_old $credentials_add > $credentials_new
  curl::execute "-d @$credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/redis'" 200 ## Needs to be 200 on kv2
  rm -f $credentials_old $credentials_add $credentials_new
}

common::run_hook "$@"