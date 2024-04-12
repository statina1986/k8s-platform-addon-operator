#!/usr/bin/env bash

# push keycloak admin password to the location where system-spec qinstaller picks it up

source "${0%/*}/../../../common/shell/functions.sh"
source "${0%/*}/../../../common/shell/variables.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  qlog "Inserting keycloak admin password to vault for system-spec qinstaller"
  token="$(vault::get_vault_token)"
  password="$(kubectl::get_secret_opaque_kv keycloak-admin-secret KEYCLOAK_ADMIN_PASSWORD platform)"
  # note, this overwrites any other secrets in the location. don't put anything else there!
  curl::post_data '{"keycloak-password":"'"$password"'"}' "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/secret/data/installer/qvaa/keycloak'" 204
}

common::run_hook "$@"
