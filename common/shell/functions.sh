
declare -A levels=([debug]=0 [info]=1 [warn]=2 [error]=3)

function qlog_level() {
  local log_message=$2
  local log_priority=$1

  [[ ${levels[$log_priority]} ]] || return 1

  [[ $levels[$log_priority] < $levels[${LOG_LEVEL:-info}] ]] && return 2

  echo "$log_message"
}

function qlog_debug() {
  qlog_level "debug" "$@"
}
function qlog() {
  qlog_level "info" "$@"
}

function rand() {
  echo "$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c ${1-5})"
}

function curl::execute() {
  CURL_RESULT="/tmp/curl.result-$(rand)"
  CURL_DEBUG="/tmp/curl.debug-$(rand)"
  local query="curl -vs -w '%{http_code}' -o $CURL_RESULT $1 2>$CURL_DEBUG" 
  qlog_debug "Executing curl query: $query"
  CURL_STATUS=$(eval $query)    
  if [[ -n $2 && $2 != $CURL_STATUS ]] ; then
    qlog "Unexpected status: $CURL_STATUS. Expected $2"
    qlog "$(cat $CURL_DEBUG)"    
    qlog "Response: $(cat $CURL_RESULT)"
    exit 1
  fi
}

function curl::post_data() {
  local curl_data="/tmp/curl.data-$(rand)"
  echo "$1" > $curl_data
  curl::execute "--request POST --data-binary '@$curl_data' $2" $3
}

function curl::delete() {
  curl::execute "--request DELETE $1" $2
}

function common::run_hook() {
  if [[ $1 == "--config" ]] ; then
    hook::config
  else
    for row in $(jq -r '.[] | @base64' $BINDING_CONTEXT_PATH); do 
      data=$(echo ${row} | base64 -d)
      echo "[$data]" > $BINDING_CONTEXT_PATH    
      hook::trigger
    done
  fi
}

function helm::run_helm_dependency_update_hook() {
  if [[ $1 == "--config" ]] ; then
    echo '{"configVersion":"v1", "beforeHelm": 1}'
  else
    dirs=(${0%/*}/../charts/*)
    helm dependency update "${dirs[0]}"
  fi
}

function common::ensure_resources() {
  set -e
  if [[ $1 == "--config" ]] ; then
    yamls=(${0%/*}/../resources/*)
    for val in ${yamls[@]}; do
      kubectl apply -f $val &> ensure_resources.log || { 
          cat ensure_resources.log && exit 1 
      }
    done
    echo '{"configVersion":"v1", "beforeHelm": 1}'
  else
    cat ensure_resources.log
  fi
}

function kubectl::replace_or_create() {
  object=$(cat)

  if ! kubectl get -f - <<< "$object" >/dev/null 2>/dev/null; then
    kubectl create -f - <<< "$object" >/dev/null
  else
    kubectl replace --force -f - <<< "$object" >/dev/null
  fi
}

function kubectl::get_secret_opaque_kv() {
  echo "$( kubectl get secret -n $3 $1 -o jsonpath='{ .data.'$2' }' | base64 -d )"
}

function vault::get_vault_token() {
  echo "$( kubectl get secret -n platform vault-keys --template='{{ index .data "root_token" }}' | base64 -d )"
}