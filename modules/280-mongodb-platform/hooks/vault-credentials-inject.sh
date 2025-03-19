#!/usr/bin/env bash

# push MongoDB admin credentials to platform Vault

source "${0%/*}/../../../common/shell/functions.sh"
source "${0%/*}/../../../common/shell/variables.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  qlog "Inserting MongoDB credentials to Vault"
  token="$(vault::get_vault_token)"
  FULL_RELEASE_NAME="${HELM_RELEASE_NAME_PREFIX}mongodb-platform"

  # MongoDB credentials
  password="$(kubectl::get_secret_opaque_kv $FULL_RELEASE_NAME mongodb-root-password $VAULT_SECRET_NAMESPACE)"
  credentials_old=`mktemp`
  credentials_add=`mktemp`
  credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/admin/mongodb'" '200|404'
  jq -r .data $CURL_RESULT > $credentials_old
  echo '{"mongodb-password":"'"$password"'"}' > $credentials_add
  jq -s add $credentials_old $credentials_add > $credentials_new
  curl::execute "-d @$credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/admin/mongodb'" 204
  rm -f $credentials_old $credentials_add $credentials_new
}

common::run_hook "$@"