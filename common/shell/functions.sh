function common::run_hook() {
  if [[ $1 == "--config" ]] ; then
    hook::config
  else
    hook::trigger
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
  echo "$( kubectl get secret -n platform vault-dev-keys --template='{{ index .data "vault-dev-root-token" }}' | base64 -d )"
}