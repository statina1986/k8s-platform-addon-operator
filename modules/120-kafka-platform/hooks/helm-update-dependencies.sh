#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

helm::run_helm_dependency_update_hook() "$@"