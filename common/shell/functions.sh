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

MYDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"
VARIABLES_FILE=${VARIABLES_FILE:-"variables.sh"}
source "$MYDIR/$VARIABLES_FILE"

function curl::execute() {
  CURL_RESULT="/tmp/curl.result-$(rand)"
  CURL_DEBUG="/tmp/curl.debug-$(rand)"
  local query="curl -vs -w '%{http_code}' -o $CURL_RESULT $1 2>$CURL_DEBUG" 
  qlog_debug "Executing curl query: $query"
  CURL_STATUS=$(eval $query)    
  if [[ -n $2 && ! $CURL_STATUS =~ $2 ]] ; then
    qlog "Unexpected status: $CURL_STATUS. Expected $2"
    qlog "$(cat $CURL_DEBUG)"    
    qlog "Response: $(cat $CURL_RESULT)"
    exit 1
  fi
}

function curl::put_data() {
  local curl_data="/tmp/curl.data-$(rand)"
  echo "$1" > $curl_data
  curl::execute "--request PUT --data-binary '@$curl_data' $2" $3
  rm -f "$curl_data"
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

function common::get_values_value() {
  echo "$(jq -r $1 $VALUES_PATH)"
}

function common::get_config_values_value() {
  echo "$(jq -r $1 $CONFIG_VALUES_PATH)"
}

function common::module_is_enabled() {
  query="jq -r '.global.enabledModules | index( \"$1\" )' $VALUES_PATH"
  result=$(eval $query)
  re='^[0-9]+$'
  [[ $result =~ $re ]]
  return
}

function helm::run_helm_dependency_update_hook() {
  if [[ $1 == "--config" ]] ; then
    echo '{"configVersion":"v1", "beforeHelm": 1}'
  else
    dirs=(${0%/*}/../charts/*)
    if [[ ! -f "${dirs[0]}/Chart.lock" ]] ; then
      helm dependency update "${dirs[0]}"
    else
      qlog "Dependencies already downloaded. Skipping"
    fi
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
  echo "$( kubectl get secret -n $3 $1 --template="{{ index .data \"$2\" }}" | base64 -d )"
}

function vault::get_vault_token() {
  echo "$( kubectl get secret -n  $VAULT_SECRET_NAMESPACE $VAULT_SECRET_NAME --template="{{ index .data \"$VAULT_SECRET_ROOT_TOKEN\" }}" | base64 -d )"
}

function inline::get_computed_values() {
  local -n computed_values_arr=$1   
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }    
  for row in $(echo $2 | jq -r '.[] | @base64'); do
    computed_value_name=$(_jq '.name')
    computed_values_arr[$computed_value_name]=$($(_jq '.expression'))    
  done
}

function inline::process_computed_values() {
  local -n computed_values_arr=$1
  local -n result=$2  
  for i in "${!computed_values_arr[@]}"
  do
     result="${result/"{$i}"/"${computed_values_arr[$i]}"}"
  done
}

source "$MYDIR/inline-functions.sh"