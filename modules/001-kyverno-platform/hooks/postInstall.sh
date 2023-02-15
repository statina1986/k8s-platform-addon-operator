#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  qlog "Sleeping for 30 seconds in order to let Kyverno start and being able to rewrite images from subsecquent modules"
  sleep 30
}

common::run_hook "$@"