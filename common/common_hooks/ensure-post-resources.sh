#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

set -e
if [[ $1 == "--config" ]] ; then
    echo '{"configVersion":"v1", "afterHelm": 1}'
else
    if [[ $ADDON_OPERATOR_DEPLOY_RESOURCES == "true" ]] ; then
        if [[ ! -f "${0%/*}/../post-resources/" ]] ; then
            yamls=(${0%/*}/../post-resources/*)
            for val in "${yamls[@]}"; do
                if [[ $val == *.yaml ]] ; then
                    kubectl apply --server-side --force-conflicts=true -f $val &> /tmp/ensure_resources.log || { 
                        cat ensure_resources.log && exit 1 
                    }
                fi
            done
        fi
        if [[ -f "/tmp/ensure_resources.log" ]] ; then
            cat /tmp/ensure_resources.log
        fi 
    else
        echo "Skipping resources"
    fi  
fi