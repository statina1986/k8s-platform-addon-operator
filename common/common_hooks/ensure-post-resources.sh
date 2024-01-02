#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

set -e
if [[ $1 == "--config" ]] ; then
    echo '{"configVersion":"v1", "afterHelm": 1}'
else
    if [[ ! -f "${0%/*}/../post-resources/" ]] ; then
        yamls=(${0%/*}/../post-resources/*)
        for val in "${yamls[@]}"; do
        if [[ $val == *.yaml ]] ; then
            kubectl apply --server-side --force-conflicts=true -f $val &> ensure_resources.log || { 
                cat ensure_resources.log && exit 1 
            }
        fi
        done
    fi
    if [[ -f "ensure_resources.log" ]] ; then
        cat ensure_resources.log
    fi   
fi