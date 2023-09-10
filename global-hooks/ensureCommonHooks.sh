#!/usr/bin/env bash

source "${0%/*}/../common/shell/functions.sh"

if [[ $1 == "--config" ]] ; then
    echo '{"configVersion":"v1", "beforeAll": 1}'
  else
    commonHooks=(
        "${0%/*}/../common/common_hooks/template-mako.py"
        "${0%/*}/../common/common_hooks/update-deployment-progress.py"
        "${0%/*}/../common/common_hooks/ensureResources.sh"
    )
    dirs=(${0%/*}/../modules/*/)
    for dir in "${dirs[@]}"; do
        for hook in "${commonHooks[@]}"; do            
            mkdir -p "$dir/hooks" && cp "$hook" "$dir/hooks/"
        done
    done 
  fi