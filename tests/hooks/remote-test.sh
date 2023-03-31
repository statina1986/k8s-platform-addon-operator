#!/usr/bin/env bash

if [[ $2 == "--config" ]] ; then
    $1 $2
    exit 0
fi
timestamp=$(date +%Y%m%d%H%M%S)
ADDON_OPERATOR_POD=$(kubectl get pod -n platform -l app=addon-operator -o jsonpath="{.items[0].metadata.name}")
hook_name=$(basename "$1")
kubectl exec -n platform "$ADDON_OPERATOR_POD" -- /bin/bash -c "mkdir -p /tests/hooks/$timestamp"
kubectl cp -n platform "$1" "$ADDON_OPERATOR_POD:/tests/hooks/$timestamp/$hook_name"
if [[ $2 == "" ]] ; then
    kubectl exec -n platform "$ADDON_OPERATOR_POD" -- /bin/bash -c "/tests/hooks/$timestamp/$hook_name" 
else
    context_name=$(basename "$2")
    kubectl cp -n platform "$2" "$ADDON_OPERATOR_POD:/tests/hooks/$timestamp/$context_name"
    kubectl exec -n platform "$ADDON_OPERATOR_POD" -- /bin/bash -c "export BINDING_CONTEXT_PATH=/tests/hooks/$timestamp/$context_name && /tests/hooks/$timestamp/$hook_name" 
fi


