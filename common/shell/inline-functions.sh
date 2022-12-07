function inline::string() {
  echo "$1"
}

function inline::aws::get_secret_value() {
  echo "$( aws secretsmanager get-secret-value --secret-id $1 --query $2 --output text )"
}

function inline::k8s::create_username_and_password_secret() {
  local secretname=$1
  local secretnamespace=$2
  local username=$3
  local password=$4
  if [ -z "$password" ] ; then
    password=$(rand 12)
  fi

  kubectl delete secret $secretname -n $secretnamespace --ignore-not-found >/dev/null 2>/dev/null;

  kubectl create secret generic $secretname -n $secretnamespace \
    --from-literal=username="$username" \
    --from-literal=password="$password" \
    >/dev/null 2>/dev/null;
  echo "$password"
}
