#!/usr/bin/env bash

# push keycloak admin password to the location where system-spec qinstaller picks it up

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
  
  qlog "Inserting keycloak admin password to vault for system-spec qinstaller"
  token="$(vault::get_vault_token)"
  password="$(kubectl::get_secret_opaque_kv keycloak-admin-secret KEYCLOAK_ADMIN_PASSWORD $VAULT_SECRET_NAMESPACE)"
  OLD=`mktemp`
  ADD=`mktemp`
  NEW=`mktemp`
  # read old data from vault, accept also not found
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/installer/qvaa/keycloak'" '200|404'
  jq -r .data $CURL_RESULT > $OLD
  echo '{"keycloak-password":"'"$password"'"}' > $ADD
  # combine old data (possibly null) with new
  jq -s add $OLD $ADD > $NEW
  # put new data to vault
  curl::execute "-d @$NEW --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/installer/qvaa/keycloak'" 204
  rm -f $OLD $ADD $NEW

  qlog "Inserting keycloak admin password to platform-secret kv2 Vault"
  OLD=`mktemp`
  ADD=`mktemp`
  NEW=`mktemp`
  # read old data from vault, accept also not found
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/keycloak'" '200|404'
  jq -r .data $CURL_RESULT > $OLD
  echo '{"data": {"keycloak-password":"'"$password"'"}}' > $ADD
  # combine old data (possibly null) with new
  jq -s add $OLD $ADD > $NEW
  # put new data to vault
  curl::execute "-d @$NEW --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/keycloak'" 200 ## Needs to be 200 on kv2
  rm -f $OLD $ADD $NEW
}

common::run_hook "$@"
