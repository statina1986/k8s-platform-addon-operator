#!/usr/bin/env bash

source "${0%/*}/../common/shell/functions.sh"

if [[ $1 == "--config" ]] ; then
    echo '{"configVersion":"v1", "beforeAll": 1}'
  else    
    dirs=(${0%/*}/../modules/*/)
    for dir in "${dirs[@]}"; do
        cp -n "${0%/*}/../common/common_files/.helmignore" "$dir/.helmignore" || true
    done 
  fi