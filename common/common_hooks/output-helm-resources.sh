#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

set -e
if [[ $1 == "--config" ]] ; then
    echo '{"configVersion":"v1", "beforeHelm": 1}'
else        
    module=$(basename $(dirname "${0%/*}"))
    echo $module    
    mkdir -p /tmp/helm_output
    mkdir -p /tmp/helm_output/$module
    cat "$VALUES_PATH" |  yq -P > "/tmp/helm_output/$module/values.yaml"
    helm template ${0%/*}/../ -f "/tmp/helm_output/$module/values.yaml" > /tmp/helm_output/$module/resources.yaml
fi

