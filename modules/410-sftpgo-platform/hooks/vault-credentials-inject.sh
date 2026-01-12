#!/usr/bin/env bash

# push SFTPGo admin credentials to platform Vault

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
  
  qlog "Inserting SFTPGo admin credentials to platform-secret kv2 Vault"
  token="$(vault::get_vault_token)"
  password="$(kubectl::get_secret_opaque_kv sftpgo-admin-secret password $VAULT_SECRET_NAMESPACE)"
  credentials_old=`mktemp`
  credentials_add=`mktemp`
  credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/sftpgo'" '200|404'
  jq -r .data $CURL_RESULT > $credentials_old
  echo '{"data": {"password":"'"$password"'"}}' > $credentials_add
  jq -s add $credentials_old $credentials_add > $credentials_new
  curl::execute "-d @$credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/sftpgo'" 200 ## Needs to be 200 on kv2
  rm -f $credentials_old $credentials_add $credentials_new
}

common::run_hook "$@"