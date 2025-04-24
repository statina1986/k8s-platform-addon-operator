#!/usr/bin/env bash

# push MinIO admin credentials to platform Vault

source "${0%/*}/../../../common/shell/functions.sh"
source "${0%/*}/../../../common/shell/variables.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  qlog "Inserting MinIO root credentials to platform-secret kv2 Vault"
  token="$(vault::get_vault_token)"
  
  password="$(kubectl::get_secret_opaque_kv platform-minio-root rootPassword $VAULT_SECRET_NAMESPACE)"
  credentials_old=`mktemp`
  credentials_add=`mktemp`
  credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/minio'" '200|404'
  jq -r .data $CURL_RESULT > $credentials_old
  echo '{"data": {"minio-root-password":"'"$password"'"}}' > $credentials_add
  jq -s add $credentials_old $credentials_add > $credentials_new
  curl::execute "-d @$credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/minio'" 200 ## Needs to be 200 on kv2
  rm -f $credentials_old $credentials_add $credentials_new
}

common::run_hook "$@"