#!/usr/bin/env bash

# push Kibana readonly credentials to platform Vault

source "${0%/*}/../../../common/shell/functions.sh"
source "${0%/*}/../../../common/shell/variables.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  qlog "Inserting Kibana readonly credentials to Vault"
  token="$(vault::get_vault_token)"

  # Readonly credentials
  username="$(kubectl::get_secret_opaque_kv legacy-kibana-readonly-user username $VAULT_SECRET_NAMESPACE)"
  password="$(kubectl::get_secret_opaque_kv legacy-kibana-readonly-user password $VAULT_SECRET_NAMESPACE)"
  credentials_old=`mktemp`
  credentials_add=`mktemp`
  credentials_new=`mktemp`
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/readonly/legacy-kibana'" '200|404'
  jq -r .data $CURL_RESULT > $readonly_old
  echo '{"legacy-kibana-readonly-username":"'"$username"'"}' > $credentials_add
  echo '{"legacy-kibana-readonly-password":"'"$password"'"}' >> $credentials_add
  jq -s add $credentials_old $credentials_add > $credentials_new
  curl::execute "-d @$credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/platform/readonly/legacy-kibana'" 204
  rm -f $credentials_old $credentials_add $credentials_new
}

common::run_hook "$@"