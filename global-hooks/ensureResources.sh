#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

set -e
if [[ $1 == "--config" ]] ; then
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
    echo '{"configVersion":"v1", "onStartup": 1}'
else
    if [[ -f "ensure_resources.log" ]] ; then
        cat ensure_resources.log
    fi
   
fi