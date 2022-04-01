#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  echo '{"configVersion":"v1", "onStartup": 1}'
}

hook::trigger() {
  token="$(vault::get_vault_token)"
  aurora_username="$(kubectl::get_secret_opaque_kv 'aurora-mysql-db-admin' 'username' 'platform')"
  aurora_password="$(kubectl::get_secret_opaque_kv 'aurora-mysql-db-admin' 'password' 'platform')"
  endpoint=$(jq -r '.auroraMysqlDb.endpoint' $VALUES_PATH)

  
  kubectl exec -n platform vault-0 -- /bin/sh -c "vault login -no-print $token && \
    vault write database/config/x-aurora-mysql-database \
        plugin_name=mysql-aurora-database-plugin \
        connection_url='{{username}}:{{password}}@tcp($endpoint:3306)/' \
        allowed_roles='*' \
        username='$aurora_username' \
        password='$aurora_password'"
}

common::run_hook "$@"