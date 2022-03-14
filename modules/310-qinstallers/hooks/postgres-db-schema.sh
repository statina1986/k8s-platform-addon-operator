#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  cat <<EOF
{
  "configVersion":"v1",
  "kubernetes":[{
    "name": "Provision postgres schemas",
    "kind": "QInstaller",
    "executeHookOnEvent":["Added","Modified","Deleted"]
  }]
}
EOF
}

hook::trigger() {
  type=$(jq -r '.[0].type' ${BINDING_CONTEXT_PATH})

  if [[ $type == "Synchronization" ]] ; then
    echo "Skipping current items on startup"

  elif [[ $type == "Event" ]] ; then
    event=$(jq -r '.[0].watchEvent' ${BINDING_CONTEXT_PATH})

    name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
    db_provision_sql=$(jq -r '.[0].object.spec."db-provision-sql"' ${BINDING_CONTEXT_PATH})
    secret=$(jq -r '.[0].object.spec."db-secret-name"' ${BINDING_CONTEXT_PATH})
    db_url=$(jq -r '.[0].object.spec."db-url"' ${BINDING_CONTEXT_PATH})
    echo "$secret"
    rand=`head -c 5 /dev/random | md5sum | head -c 5`
    aurora_username="$(kubectl::get_secret_opaque_kv $secret 'username' 'platform')"
    echo "$aurora_username"
    aurora_password="$(kubectl::get_secret_opaque_kv $secret 'password' 'platform')"
    echo "$aurora_password"
    echo "${db_provision_sql}" > db_provision.sql
    kubectl run -n platform "postgre-db-provision-$rand" --image=tmaier/postgresql-client --command -- /bin/sh -c "tail -f /dev/null"
    kubectl wait --for=condition=ready --timeout=30s pod/"postgre-db-provision-$rand" -n platform
    kubectl cp db_provision.sql "platform/postgre-db-provision-$rand":/
    kubectl exec -n platform "postgre-db-provision-$rand" -- psql "postgresql://${aurora_username}:${aurora_password}@${db_url}" -a -f /db_provision.sql
    kubectl delete pod -n platform "postgre-db-provision-$rand"

#mmlyle-preprod-postgresql.cluster-cqymmwsbl6uh.eu-central-1.rds.amazonaws.com:5432/postgres

    # if [[ $event == "Deleted" ]] ; then
    #   name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
    #   role_name=$(jq -r '.[0].object.spec."role-name"' ${BINDING_CONTEXT_PATH}) 
    #   token="$(vault::get_vault_token)"

    #   kubectl exec -n platform vault-0 -- /bin/sh -c "vault login -no-print $token && \
    #     vault delete database/roles/$role_name"

    # else
    #   name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
    #   role_name=$(jq -r '.[0].object.spec."role-name"' ${BINDING_CONTEXT_PATH}) 
    #   db_name=$(jq -r '.[0].object.spec."db-name"' ${BINDING_CONTEXT_PATH})
    #   max_ttl=$(jq -r '.[0].object.spec."max-ttl"' ${BINDING_CONTEXT_PATH})
    #   default_ttl=$(jq -r '.[0].object.spec."default-ttl"' ${BINDING_CONTEXT_PATH})
    #   creation_statement=$(jq -r '.[0].object.spec."creation-statement"' ${BINDING_CONTEXT_PATH})

    #   token="$(vault::get_vault_token)"

    #   kubectl exec -n platform vault-0 -- /bin/sh -c "vault login -no-print $token && \
    #     vault write database/roles/$role_name \
    #       db_name=$db_name \
    #       creation_statements=\"$creation_statement\" \
    #       default_ttl=$default_ttl \
    #       max_ttl=$max_ttl"
    # fi
  fi
}

common::run_hook "$@"