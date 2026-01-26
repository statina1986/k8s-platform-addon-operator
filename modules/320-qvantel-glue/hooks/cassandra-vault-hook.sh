#!/usr/bin/env bash

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
  
  qlog "Inserting Cassandra credentials for all clusters to platform-secret KV2 Vault"

  token="$(vault::get_vault_token)"

  # Get all cluster names from values
  mapfile -t clusters < <(common::get_values_value '.qvantelGlue.dbs.cassandra' | jq -r 'keys[]')
  if [[ ${#clusters[@]} -eq 0 ]]; then
    qlog "No Cassandra clusters found in values"
    exit 0
  fi
  qlog "Discovered clusters: ${clusters[*]}"

  # Prepare Vault payload
  credentials_old="$(mktemp)"
  credentials_add="$(mktemp)"
  credentials_new="$(mktemp)"
  tmp_file="$(mktemp)"

  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/cassandra'" '200|404'
  jq -r '.data // {}' "$CURL_RESULT" > "$credentials_old" || echo '{}' > "$credentials_old"

  # Build new data object
  echo '{"data":{}}' > "$credentials_add"

  for cluster in "${clusters[@]}"; do
    local secret_name="${cluster}-superuser"
    qlog "Fetching password from secret: ${secret_name}"
    local password
    if ! password="$(kubectl::get_secret_opaque_kv "$secret_name" password $ADDON_OPERATOR_NAMESPACE 2>/dev/null)"; then
      qlog "Secret ${secret_name} not found or missing password; skipping"
      continue
    fi

    # Add per-cluster key
    jq --arg key "${cluster}-superuser-password" --arg val "$password" \
       '.data[$key]=$val' "$credentials_add" > "$tmp_file" && mv "$tmp_file" "$credentials_add"
  done

  # Merge with existing Vault data
  jq -s '.[0] * .[1]' "$credentials_old" "$credentials_add" > "$credentials_new"

  # Push to Vault
  curl::execute "-d @$credentials_new --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/platform-secret/data/cassandra'" 200

  rm -f "$credentials_old" "$credentials_add" "$credentials_new" "$tmp_file"
  qlog "Vault update completed for Cassandra clusters: ${clusters[*]}"
}

common::run_hook "$@"
