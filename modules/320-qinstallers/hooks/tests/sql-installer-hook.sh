# #!/usr/bin/env bash

# source "${0%/*}/../../../common/shell/functions.sh"

# hook::config() {
#   cat <<EOF
# configVersion: v1
# kubernetes:
# - name: "Monitor SqlInstallers"
#   kind: SqlInstallers  
#   executeHookOnEvent: [ "Added", "Modified", "Deleted" ]
#   queue: SqlInstallersQueue
# EOF
# }

# hook::trigger() {
#   type=$(jq -r '.[0].type' ${BINDING_CONTEXT_PATH})

#   if [[ $type == "Synchronization" ]] ; then
#     echo "Skipping current items on startup"

#   elif [[ $type == "Event" ]] ; then
#     event=$(jq -r '.[0].watchEvent' ${BINDING_CONTEXT_PATH})
#     name=$(jq -r '.[0].object.metadata.name' ${BINDING_CONTEXT_PATH})
#     db_provision_sql=$(jq -r '.[0].object.spec."db-provision-sql"' ${BINDING_CONTEXT_PATH})
#     db_secret=$(jq -r '.[0].object.spec."db-secret-name"' ${BINDING_CONTEXT_PATH})
#     db_username=$(jq -r '.[0].object.spec."db-username"' ${BINDING_CONTEXT_PATH})
#     db_password=$(jq -r '.[0].object.spec."db-password"' ${BINDING_CONTEXT_PATH})
#     db_url=$(jq -r '.[0].object.spec."db-url"' ${BINDING_CONTEXT_PATH})
#     db_type=$(jq -r '.[0].object.spec."type"' ${BINDING_CONTEXT_PATH})
#     computed_values_json=$(jq -r '.[0].object.spec."computed-values"' ${BINDING_CONTEXT_PATH})    

#     declare -A computed_values=()
#     inline::get_computed_values computed_values "${computed_values_json}"

#     if [ -z "$db_secret" ] ; then
#       db_username="$(kubectl::get_secret_opaque_kv $db_secret 'username' 'platform')"
#       db_password="$(kubectl::get_secret_opaque_kv $db_secret 'password' 'platform')"
#     else
#       inline::process_computed_values computed_values db_username
#       inline::process_computed_values computed_values db_password
#     fi

#     inline::process_computed_values computed_values db_provision_sql
#     echo "${db_provision_sql}" > db_provision.sql
#     qlog "$db_provision_sql"
#     qlog "$db_username"
#     qlog "$db_password"

#     if [[ $db_type == "postgresql" ]] ; then      
#       kubectl run -n platform "postgre-db-provision-$(rand)" --image=artifactory.qvantel.net/k8s-platform-tools --command -- /bin/sh -c "tail -f /dev/null"
#       kubectl wait --for=condition=ready --timeout=30s pod/"postgre-db-provision-$(rand)" -n platform
#       kubectl cp db_provision.sql "platform/postgre-db-provision-$(rand)":/
#       kubectl exec -n platform "postgre-db-provision-$(rand)" -- psql "postgresql://${username}:${password}@${db_url}" -a -f /db_provision.sql
#       kubectl delete pod -n platform "postgre-db-provision-$(rand)"
#     elif [[ $db_type == "mariadb" ]] ; then     
#       kubectl run -n platform "mariadb-db-provision-$(rand)" --image=artifactory.qvantel.net/k8s-platform-tools --command -- /bin/sh -c "tail -f /dev/null"
#       kubectl wait --for=condition=ready --timeout=30s pod/"mariadb-db-provision-$(rand)" -n platform
#       kubectl cp db_provision.sql "platform/mariadb-db-provision-$(rand)":/
#       kubectl exec -n platform "mariadb-db-provision-$(rand)" -- /bin/sh -c "mysql -u $username -p$password --host=$db_url < /db_provision.sql"
#       kubectl delete pod -n platform "mariadb-db-provision-$(rand)"
#     fi
#   fi
# }

# common::run_hook "$@"