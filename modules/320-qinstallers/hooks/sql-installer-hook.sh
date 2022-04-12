#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  cat <<EOF
configVersion: v1
kubernetes:
- name: "Monitor SqlInstallers"
  kind: SqlInstallers  
  executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
  queue: SqlInstallersQueue
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
    db_type=$(jq -r '.[0].object.spec."type"' ${BINDING_CONTEXT_PATH})
    rand=`head -c 5 /dev/random | md5sum | head -c 5`
    echo "${db_provision_sql}" > db_provision.sql
    
    if [[ $db_type == "postgresql" ]] ; then
      username="$(kubectl::get_secret_opaque_kv $secret 'username' 'platform')"
      password="$(kubectl::get_secret_opaque_kv $secret 'password' 'platform')"
      kubectl run -n platform "postgre-db-provision-$rand" --image=artifactory.qvantel.net/k8s-platform-tools --command -- /bin/sh -c "tail -f /dev/null"
      kubectl wait --for=condition=ready --timeout=30s pod/"postgre-db-provision-$rand" -n platform
      kubectl cp db_provision.sql "platform/postgre-db-provision-$rand":/
      kubectl exec -n platform "postgre-db-provision-$rand" -- psql "postgresql://${username}:${password}@${db_url}" -a -f /db_provision.sql
      kubectl delete pod -n platform "postgre-db-provision-$rand"
    elif [[ $db_type == "mariadb" ]] ; then
      username="root"
      password="$(kubectl::get_secret_opaque_kv $secret 'mariadb-root-password' 'platform')"
      kubectl run -n platform "mariadb-db-provision-$rand" --image=artifactory.qvantel.net/k8s-platform-tools --command -- /bin/sh -c "tail -f /dev/null"
      kubectl wait --for=condition=ready --timeout=30s pod/"mariadb-db-provision-$rand" -n platform
      kubectl cp db_provision.sql "platform/mariadb-db-provision-$rand":/
      kubectl exec -n platform "mariadb-db-provision-$rand" -- /bin/sh -c "mysql -u $username -p$password --host=$db_url < /db_provision.sql"
      kubectl delete pod -n platform "mariadb-db-provision-$rand"
    fi
  fi
}

common::run_hook "$@"