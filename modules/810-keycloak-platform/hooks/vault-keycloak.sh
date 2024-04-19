#!/usr/bin/env bash

# optionally configure vault with keycloak integration
# do note this is somewhat difficult to get working locally. It needs a keycloak that can be accessed with the same
# name both inside the k8s cluster and outside the cluster (with a web browser).
# by default, keycloak is auth-domain-name.qvantel.systems and if that works inside the cluster,
# that's okay. Again by default, that keycloak should have a certificate from a commonly trusted CA.
# if the cert for keycloak is not from a commonly trusted CA, it needs to be added in configuration.

source "${0%/*}/../../../common/shell/functions.sh"
source "${0%/*}/../../../common/shell/variables.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  enabled="$(common::get_values_value '.keycloakPlatform.vaultIntegration.enabled')"
  if [[ $enabled == "false" ]] ; then
    qlog "Vault Keycloak integration not enabled"
    exit 0
  fi

  qlog "Configure Vault with keycloak logins"
  token="$(vault::get_vault_token)"

  discovery_url="$(common::get_values_value '.keycloakPlatform.vaultIntegration.discovery_url')"
  cacert="$(jq .keycloakPlatform.vaultIntegration.oidc_discovery_ca_pem < $VALUES_PATH)"
  if [ "$cacert" == 'false' ]
  then
    qlog "oidc_discovery_ca_pem was not defined"
    vaultcaopt=""
    curlcaopt=""
  else
    qlog "oidc_discovery_ca_pem defined, using custom ca cert"
    vaultcaopt=",\"oidc_discovery_ca_pem\":$cacert"
    FILE=`mktemp`
    jq -r .keycloakPlatform.vaultIntegration.oidc_discovery_ca_pem < $VALUES_PATH > $FILE
    curlcaopt="--cacert $FILE"
  fi
  # ensure we can contact keycloak and there is some good url. It's different than vault contacting keycloak though.
  curl::execute "$curlcaopt $discovery_url/.well-known/openid-configuration" 200

  qlog "list auth methods"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/auth'" 200
  qlog "ensure oidc auth method is enabled"
  if [ ! "$(jq 'has("oidc/")' $CURL_RESULT)" == "true" ]; then
    curl::post_data '{"type":"oidc","description":"","config":{"options":null,"default_lease_ttl":"0s","max_lease_ttl":"0s","force_no_cache":false},"local":false,"seal_wrap":false,"external_entropy_access":false,"options":null}' \
      "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/auth/oidc'" 204
  fi

  qlog "put acl policies"
  policynames=`jq -r '.keycloakPlatform.vaultIntegration.policies | keys[]' < $VALUES_PATH`
  for policyname in $policynames
  do
    qlog "put policy $policyname"
    curl::put_data "{\"policy\": $(jq .keycloakPlatform.vaultIntegration.policies.$policyname < $VALUES_PATH) }" "--header 'Content-Type: application/json' --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/policies/acl/$policyname'" 204
  done

  qlog "configure oidc"
  secret="$(kubectl::get_secret_opaque_kv vault-client-secret VAULT_CLIENT_SECRET platform)"
  curl::put_data '{"default_role":"default","oidc_client_id":"vault","oidc_client_secret":"'$secret'","oidc_discovery_url":"'$discovery_url'"'"$vaultcaopt"'}' \
      "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/auth/oidc/config'" 204

  qlog "configure oidc default role"
  curl::put_data '{"allowed_redirect_uris":"http://localhost:8250/oidc/callback,'"$(common::get_values_value '.keycloakPlatform.vaultIntegration.vault_url')"'","groups_claim":"/realm_access/roles","oidc_scopes":"email","policies":"default","ttl":"1h","user_claim":"preferred_username"}' \
      "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/auth/oidc/role/default'" 204

  qlog "list groups"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/identity/group/id?list=true'" '200|404'
  if [ $CURL_STATUS == 200 ]; then
    qlog "delete existing groups"
    groupkeys=`jq -r .data.keys[] $CURL_RESULT`
    for key in $groupkeys
    do
      qlog "delete key $key"
      curl::delete "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/identity/group/id/$key'" 204
    done
  fi

  qlog "get accessor for oidc"
  curl::execute "--header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/sys/auth'" 200
  accessor="$(jq -r .data.\"oidc/\".accessor $CURL_RESULT)"

  groupnames=`jq -r '.keycloakPlatform.vaultIntegration.groups | keys[]' < $VALUES_PATH`
  for groupname in $groupnames
  do
    qlog "create group $groupname"
    curl::post_data "{\"name\": \"$groupname\", \"type\": \"external\", \"policies\": $(jq .keycloakPlatform.vaultIntegration.groups.$groupname.policies < $VALUES_PATH) }" "--header 'Content-Type: application/json' --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/identity/group'" '200|204'
    groupid="$(jq -r .data.id $CURL_RESULT)"
    qlog "create group alias for $groupname"
    curl::post_data "{\"canonical_id\":\"$groupid\",\"mount_accessor\":\"$accessor\",\"name\":\"$(jq -r .keycloakPlatform.vaultIntegration.groups.$groupname.value < $VALUES_PATH)\"}" "--header 'Content-Type: application/json' --header 'X-Vault-Token: $token' '$VAULT_ADDR/v1/identity/group-alias'" '200|204'
  done
  qlog "Done configuring oidc for vault"
}

common::run_hook "$@"
