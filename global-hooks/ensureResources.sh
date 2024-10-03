#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

set -e
if [[ $1 == "--config" ]] ; then
    if [[ $ADDON_OPERATOR_DEPLOY_RESOURCES == "true" ]] ; then
        echo "Applying resources" &> ensure_resources.log
        if [[ ! -f "${0%/*}/../resources/" ]] ; then
            yamls=(${0%/*}/../resources/*)
            for val in "${yamls[@]}"; do
                if [[ $val == *.yaml ]] ; then
                    kubectl apply --server-side --force-conflicts=true -f $val &> ensure_resources.log || { 
                        cat ensure_resources.log && exit 1 
                    }
                fi
            done
        fi
    else
        echo "Skipping resources" &> ensure_resources.log
    fi
    echo '{"configVersion":"v1", "onStartup": 2}'
else
    if [[ -f "ensure_resources.log" ]] ; then
        cat ensure_resources.log
    fi
fi