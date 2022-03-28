function qlog () {
  echo "$(date -Iseconds) [k8s-platform] ${@}"
}

function rand () {
  echo "$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c ${1-5})"
}

function curl::execute() {
  curl_result="/tmp/curl.result-$(rand)"
  curl_debug="/tmp/curl.debug-$(rand)"
  query="curl -vs -w '%{http_code}' -o $curl_result $1 2>$curl_debug" 
  qlog "Executing curl query: $query"
  status=$(eval $query)
  qlog "$(cat $curl_debug)"
  qlog "Response: $(cat $curl_result)"
  if [[ ! $2 == $status ]] ; then
    qlog "Unexpected status: $status. Expected $2"
    exit 1
  fi
}

function curl::post_data() {
  curl_data="/tmp/curl.data-$(rand)"
  echo "$1" > $curl_data
  curl::execute "--request POST --data-binary '@$curl_data' $2" $3
}

function common::run_hook() {
  if [[ $1 == "--config" ]] ; then
    hook::config
  else
    hook::trigger
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
  echo "$( kubectl get secret -n $3 $1 --template='{{ index .data.'$2' }}' | base64 -d )"
}

function vault::get_vault_token() {
  echo "$( kubectl get secret -n vault vault-keys --template='{{ index .data "root_token" }}' | base64 -d )"
}