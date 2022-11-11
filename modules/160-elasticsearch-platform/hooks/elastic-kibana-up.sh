#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  PORT=5601
  URL="http://kibana-kb-http:$PORT"
  status_code=0
  while [ "200" != $status_code  ]
  do
    SECRET="$(kubectl get secret -n platform logsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 -d)"
    echo "Sleeping for 50 seconds..."
    sleep 50
    echo "Trying to contact Kibana at $URL"
    status_code=$(curl -u elastic:$SECRET --write-out %{http_code} --silent --output /dev/null "$URL"/status -I)
    echo "status code $status_code"
  done
  kubectl apply -f "${0%/*}/../logging-setup.yaml"
  kubectl apply -f "${0%/*}/../snapshots.yaml"
}
common::run_hook "$@"