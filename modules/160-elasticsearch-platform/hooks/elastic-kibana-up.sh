#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  PORT=5601
  URL="http://kibana-kb-http:$PORT"
  SECRET="$(kubectl get secret -n platform logsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 -d)"
  status_code=$(curl -u elastic:$SECRET --write-out %{http_code} --silent --output /dev/null "$URL"/status -I)
  while [ "200" != $status_code  ]
  do
    echo "Unable to contact Kibana on port $PORT."
    echo "Waiting for connection on $URL"
    echo "Sleeping for 50 seconds..."
    sleep 50
    status_code=$(curl -u elastic:$SECRET --write-out %{http_code} --silent --output /dev/null "$URL"/status -I)
  done
  kubectl apply -f "${0%/*}/../templates/logging-setup.yaml"
}
common::run_hook "$@"