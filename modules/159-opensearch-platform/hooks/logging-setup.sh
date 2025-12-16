#!/usr/bin/env bash
# set -euo pipefail
# IFS=$'\n\t'

source "${0%/*}/../../../common/shell/functions.sh"
source "${0%/*}/../../../common/shell/variables.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  enabled="$(common::get_values_value '.opensearchPlatform.loggingSetup.enabled')"
  if [[ $enabled != "true" ]] ; then
    qlog "Opensearch logging setup not enabled"
    exit 0
  fi

  qlog "Starting OpenSearch logging setup hook"
  # Fetch secrets from Kubernetes
  ADMINPASS="$(kubectl::get_secret_opaque_kv opensearch-initial-password OPENSEARCH_INITIAL_ADMIN_PASSWORD $ADDON_OPERATOR_NAMESPACE)"
  READWRITEPASS="$(kubectl::get_secret_opaque_kv opensearch-dashboards-readwrite password $ADDON_OPERATOR_NAMESPACE)"
  READONLYPASS="$(kubectl::get_secret_opaque_kv opensearch-dashboards-readonly password $ADDON_OPERATOR_NAMESPACE)"

  BASE_URL="https://${HELM_RELEASE_NAME_PREFIX}opensearch-cluster-master.${ADDON_OPERATOR_NAMESPACE}.svc:9200"
  CURL_AUTH="-k -u admin:${ADMINPASS}"
  CURL_HEADERS="-H 'Content-Type: application/json' -H 'osd-xsrf: true'"
  LONGTERM_RETENTION="$(common::get_values_value '.opensearchPlatform.loggingSetup.longtermRetentionPeriod')"
  SHORTTERM_RETENTION="$(common::get_values_value '.opensearchPlatform.loggingSetup.shorttermRetentionPeriod')"

  # Building bash array of all indices from yaml using mapfile for easier iteration
  mapfile -t ALL_INDICES < <(jq -r '
    .opensearchPlatform.loggingSetup
    | [ (.shorttermIndices // [])[], (.longtermIndices // [])[] ]
    | .[]
  ' "$VALUES_PATH")

  # Doing the same per retention setting
  readarray -t SHORTTERM_INDICES < <(jq -r '.opensearchPlatform.loggingSetup.shorttermIndices // [] | .[]' "$VALUES_PATH")
  readarray -t LONGTERM_INDICES < <(jq -r '.opensearchPlatform.loggingSetup.longtermIndices // [] | .[]' "$VALUES_PATH")

  ## Ensure Opensearch is up and ready
  if kubectl -n ${ADDON_OPERATOR_NAMESPACE} rollout status statefulset/opensearch-cluster-master --timeout=5m; then
    qlog "Opensearch is up, proceeding"
    # Adding sleep because sometimes Security engine wasn't initialised for user creation
    sleep 1
  else
    qlog "Opensearch took more than 5 minutes to be ready, exiting"
    exit 1
  fi
  
  # User creation
  qlog "create Opensearch internal users"
  curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_security/api/internalusers/readonly -d '{\"password\":\"${READONLYPASS}\"}'" '201|200'
  curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_security/api/internalusers/readwrite -d '{\"password\":\"${READWRITEPASS}\"}'" '201|200'

  # General logger role, Vector wants to run a health check towards the cluster
  qlog "create Opensearch logger role"
  curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_security/api/roles/logger -d '{
    \"cluster_permissions\":[
      \"cluster:monitor/health\"
    ]}'" '201|200'

  # Per index bulk write permissions for vector
  for index in ${ALL_INDICES[@]}; do
    qlog "add write permission for Vector to ${index} index"
    curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_security/api/roles/${index}_logger -d '{
      \"index_permissions\":[{\"index_patterns\":[\"${index}*\"],
      \"allowed_actions\":[\"indices:data/write/bulk*\",\"indices:data/write/index\",\"indices:admin/create\",\"indices:admin/mapping/put\"]}]}'" '201|200'
  done

  # Role mappings (overwrite safely)
  qlog "create Opensearch rolemappings"
  # Internal roles for readonly & readwrite user
  curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_security/api/rolesmapping/readall -d '{\"users\":[\"readonly\"]}'" '201|200'
  curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_security/api/rolesmapping/kibana_user -d '{\"users\":[\"readwrite\"]}'" '201|200'
  # Our generic logger role followed by per index write roles
  curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_security/api/rolesmapping/logger -d '{\"users\":[\"readwrite\"]}'" '201|200'
  for index in ${ALL_INDICES[@]}; do
    curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_security/api/rolesmapping/${index}_logger -d '{\"users\":[\"readwrite\"]}'" '201|200'
  done

  # Index templates
  for template in ${ALL_INDICES[@]}; do
    qlog "create Opensearch template: ${template} "
    curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_index_template/${template}_template -d '{
      \"index_patterns\":[\"${template}*\"],
      \"priority\":50,
      \"template\":{\"aliases\":{\"${template}\":{}},\"settings\":{\"number_of_replicas\":0}}}'" '201|200'
  done

  # ISM policies
  # shortterm policies with configured retention
  for index in ${SHORTTERM_INDICES[@]}; do
    qlog "create Opensearch ISM policy: ${index}_${SHORTTERM_RETENTION}_retention"
    curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_ism/policies/${index}_${SHORTTERM_RETENTION}_retention -d '{
      \"policy\":{\"description\":\"Retention configuration\",\"default_state\":\"hot\",\"schema_version\":1,
      \"states\":[{\"name\":\"hot\",\"actions\":[{\"index_priority\":{\"priority\":51}}],
      \"transitions\":[{\"state_name\":\"delete\",\"conditions\":{\"min_index_age\":\"${SHORTTERM_RETENTION}\"}}]},
      {\"name\":\"delete\",\"actions\":[{\"delete\":{}}]}],
      \"ism_template\":{\"index_patterns\":[\"${index}-*\"],\"priority\":100}}}'" '201|409'
  done

  # Longterm policy with configurable retention
  for index in ${LONGTERM_INDICES[@]}; do
    qlog "create Opensearch ISM policy: ${index}_${LONGTERM_RETENTION}_retention"
    curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X PUT ${BASE_URL}/_plugins/_ism/policies/${index}_${LONGTERM_RETENTION}_retention -d '{
      \"policy\":{\"description\":\"Retention configuration\",\"default_state\":\"hot\",\"schema_version\":1,
      \"states\":[{\"name\":\"hot\",\"actions\":[{\"index_priority\":{\"priority\":51}}],
      \"transitions\":[{\"state_name\":\"delete\",\"conditions\":{\"min_index_age\":\"${LONGTERM_RETENTION}\"}}]},
      {\"name\":\"delete\",\"actions\":[{\"delete\":{}}]}],
      \"ism_template\":{\"index_patterns\":[\"${index}-*\"],\"priority\":100}}}'" '201|409'
  done

  # Aliases
  DATE=$(date +'%Y-%m-%d')
  for alias in ${ALL_INDICES[@]}; do
    qlog "create Opensearch alias: ${alias}"
    curl::execute "${CURL_AUTH} ${CURL_HEADERS} -X POST ${BASE_URL}/_aliases?pretty -d '{
      \"actions\":[{\"add\":{\"index\":\"${alias}-${DATE}\",\"alias\":\"${alias}\",\"is_write_index\":true}}]}'" '200|404|500'
  done

  # Dashboards configuration in case OpenSearch Dashboards is enabled - equivalent to old Kibana.sh
  dashboardsEnabled="$(common::get_values_value '.opensearchPlatform.opensearchDashboardsEnabled')"
  if [[ $dashboardsEnabled == "true" ]] ; then
    qlog "OpenSearch Dashboards is enabled, creating index patterns once deployment is ready"
    DASHBOARDS_URL="http://${HELM_RELEASE_NAME_PREFIX}opensearch-platform-opensearch-dashboards.${ADDON_OPERATOR_NAMESPACE}.svc:5601"
    ## Ensure Opensearch is up and ready
    if kubectl -n ${ADDON_OPERATOR_NAMESPACE} rollout status deployment/opensearch-platform-opensearch-dashboards --timeout=5m; then
      qlog "Opensearch Dashboards is up, proceeding"
      # Adding sleep because sometimes we still got greeted by "Response: OpenSearch Dashboards server is not ready yet"
      sleep 1
    else
      qlog "Opensearch took more than 5 minutes to be ready, exiting"
      exit 1
    fi
    for index in ${ALL_INDICES[@]}; do
      qlog "create Opensearch index pattern: ${index}"
      curl::execute "${CURL_AUTH} ${CURL_HEADERS} -H 'securitytenant: global' -X POST ${DASHBOARDS_URL}/api/saved_objects/index-pattern/${index}* -d'{
        \"attributes\": {
              \"title\": \"${index}*\",
              \"timeFieldName\": \"timestamp\"
        }
      }'" '200|409'
    done
  fi

  qlog "OpenSearch logging setup completed successfully"
}

common::run_hook "$@"