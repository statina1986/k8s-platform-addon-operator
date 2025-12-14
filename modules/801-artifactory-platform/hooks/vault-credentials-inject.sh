#!/usr/bin/env bash

# push Artifactory JCR / OSS admin credentials to platform Vault

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
  
  qlog "Inserting Artifactory JCR / OSS credentials to legacy kv1 Vault"
  token="$(vault::get_vault_token)"

  username="$(kubectl::get_secret_opaque_kv artifactory-jcr-admin-secret username $VAULT_SECRET_NAMESPACE)"
  password="$(kubectl::get_secret_opaque_kv artifactory-jcr-admin-secret password $VAULT_SECRET_NAMESPACE)"
  credentials_old=`mktemp`
  credentials_add=`mktemp`
  credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/admin/artifactory-jcr'" '200|404'
  jq -r .data $CURL_RESULT > $credentials_old
  echo '{"artifactory-jcr-username":"'"$username"'"}' > $credentials_add
  echo '{"artifactory-jcr-password":"'"$password"'"}' >> $credentials_add
  jq -s add $credentials_old $credentials_add > $credentials_new
  curl::execute "-d @$credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/admin/artifactory-jcr'" 204
  rm -f $credentials_old $credentials_add $credentials_new

  oss_username="$(kubectl::get_secret_opaque_kv artifactory-oss-admin-secret username $VAULT_SECRET_NAMESPACE)"
  oss_password="$(kubectl::get_secret_opaque_kv artifactory-oss-admin-secret password $VAULT_SECRET_NAMESPACE)"
  oss_credentials_old=`mktemp`
  oss_credentials_add=`mktemp`
  oss_credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/admin/artifactory-oss'" '200|404'
  jq -r .data $CURL_RESULT > $oss_credentials_old
  echo '{"artifactory-oss-username":"'"$oss_username"'"}' > $oss_credentials_add
  echo '{"artifactory-oss-password":"'"$oss_password"'"}' >> $oss_credentials_add
  jq -s add $oss_credentials_old $oss_credentials_add > $oss_credentials_new
  curl::execute "-d @$oss_credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/admin/artifactory-oss'" 204
  rm -f $oss_credentials_old $oss_credentials_add $oss_credentials_new

  qlog "Inserting Artifactory JCR / OSS credentials to platform-secret kv2 Vault"
  credentials_old=`mktemp`
  credentials_add=`mktemp`
  credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/artifactory-jcr'" '200|404'
  jq -r .data $CURL_RESULT > $credentials_old
  echo '{"data": {"artifactory-jcr-username":"'"$username"'","artifactory-jcr-password":"'"$password"'"}}' > $credentials_add
  jq -s add $credentials_old $credentials_add > $credentials_new
  curl::execute "-d @$credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/artifactory-jcr'" 200 ## Needs to be 200 on kv2
  rm -f $credentials_old $credentials_add $credentials_new

  oss_credentials_old=`mktemp`
  oss_credentials_add=`mktemp`
  oss_credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/artifactory-oss'" '200|404'
  jq -r .data $CURL_RESULT > $oss_credentials_old
  echo '{"data": {"artifactory-oss-username":"'"$oss_username"'","artifactory-oss-password":"'"$oss_password"'"}}' > $oss_credentials_add
  jq -s add $oss_credentials_old $oss_credentials_add > $oss_credentials_new
  curl::execute "-d @$oss_credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/artifactory-oss'" 200 ## Needs to be 200 on kv2
  rm -f $oss_credentials_old $oss_credentials_add $oss_credentials_new
}

common::run_hook "$@"