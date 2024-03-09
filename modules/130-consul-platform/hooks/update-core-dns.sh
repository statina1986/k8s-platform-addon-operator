#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"

hook::config() {
  echo '{"configVersion":"v1", "afterHelm": 1}'
}

hook::trigger() {
  local enabled="$(common::get_values_value '.consulPlatform.updateCoreDns.enabled')"
  if [[ $enabled == "true" ]] ; then
    local configmap_name="$(common::get_values_value '.consulPlatform.updateCoreDns.configmapName')"
    local configmap_namespace="$(common::get_values_value '.consulPlatform.updateCoreDns.configmapNamespace')"
    
    coredns_config="$(kubectl get configmap/$configmap_name -n $configmap_namespace --output jsonpath='{.data.Corefile}')"

    if [[ $coredns_config == *"consul"* ]] ; then
      qlog "Consul DNS already registered within CoreDNS"
    else
      consul_ip=$(kubectl get svc -n platform consul-platform-consul-dns --output jsonpath='{.spec.clusterIP}')
      qlog "Enabling Consul DNS within CoreDNS with IP: $consul_ip"
      new_core_file=$(printf '%s' "{\"data\":{\"Corefile\":\"$coredns_config
  consul { 
      errors
      cache 30
      forward . $consul_ip
  }\"}}" | jq -sR .)
      command="kubectl patch configmap/$configmap_name -n $configmap_namespace -p $new_core_file --type=merge"
      eval "$command"
    fi 
  else
    qlog "CoreDNS rewrite is not enabled"
  fi
}

common::run_hook "$@"