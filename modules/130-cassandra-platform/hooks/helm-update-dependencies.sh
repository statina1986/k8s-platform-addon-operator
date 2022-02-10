#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  echo '{"configVersion":"v1", "beforeHelm": 1}'
}

hook::trigger() {
  helm dependency update "${0%/*}/../Chart.yaml"
}

common::run_hook "$@"