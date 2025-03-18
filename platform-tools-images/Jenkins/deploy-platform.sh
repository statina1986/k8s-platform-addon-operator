#!/usr/bin/env bash

set -e 

#trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

ADDON_OPERATOR_DEPLOYMENT_NAME=${ADDON_OPERATOR_DEPLOYMENT_NAME:-"addon-operator"}
KPLAT_RELEASE_NAME=${KPLAT_RELEASE_NAME:-"k8s-platform"}
KPLAT_NAMESPACE=${KPLAT_NAMESPACE:-"platform"}
KPLAT_REPO=${KPLAT_REPO:-"https://artifactory.qvantel.net/artifactory/all-helm/"}
KPLAT_CHART=${KPLAT_CHART:-"k8s-platform-addon-operator"}
KPLAT_CHART_VERSION=${KPLAT_CHART_VERSION:-""}
HELM_VALUES=${HELM_VALUES:-""}
HELM_SET=${HELM_SET:-""}
TIMEOUT=${TIMEOUT:-"600s"}


START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PLATFORM_READY=$(kubectl get dss -n $KPLAT_NAMESPACE platform-deployment -o=jsonpath="{$.status.conditions[?(@.type=='Ready')].status}" || echo "False")

# Here we deploy platform helm chart with custom configuration
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [[ -n $KPLAT_CHART_VERSION ]] ; then
    helm upgrade --install $KPLAT_RELEASE_NAME -n $KPLAT_NAMESPACE --create-namespace \
        --repo $KPLAT_REPO --version $KPLAT_CHART_VERSION $KPLAT_CHART $HELM_VALUES $HELM_SET
else
    helm upgrade --install $KPLAT_RELEASE_NAME -n $KPLAT_NAMESPACE --create-namespace \
        --repo $KPLAT_REPO $KPLAT_CHART $HELM_VALUES $HELM_SET
fi

DEPLOYMENT_AVAILABLE="False"
REPLICAS=0
until [[ ($DEPLOYMENT_AVAILABLE = "True") && ($REPLICAS = "1") ]]
do
    echo "Waiting for addon-operator deployment to be available"
    sleep 5
    DEPLOYMENT_AVAILABLE=$(kubectl get deployment $ADDON_OPERATOR_DEPLOYMENT_NAME -n $KPLAT_NAMESPACE -o jsonpath="{.status.conditions[?(@.type=='Available')].status}")
    REPLICAS=$(kubectl get deployment $ADDON_OPERATOR_DEPLOYMENT_NAME -n $KPLAT_NAMESPACE -o jsonpath="{.status.replicas}")
done

ADDON_OPERATOR_POD=$(kubectl get pod -n $KPLAT_NAMESPACE -l app=$ADDON_OPERATOR_DEPLOYMENT_NAME -o jsonpath="{.items[0].metadata.name}")
echo "$ADDON_OPERATOR_POD"
# kubectl logs $ADDON_OPERATOR_POD -n $KPLAT_NAMESPACE -f --since-time=$START_TIME &

N=30
while [[ $PLATFORM_READY = "True" ]]
do
    if [[ $N -lt 0 ]] ; then
        echo "Platform is already in the Ready state. Exiting."        
        exit 0
    fi
    echo "Waiting for platform to restart"
    sleep 5
    N=$N-5
    PLATFORM_READY=$(kubectl get dss -n $KPLAT_NAMESPACE platform-deployment -o=jsonpath="{$.status.conditions[?(@.type=='Ready')].status}" || echo "False")
done

N=1800
until [[ $PLATFORM_READY = "True" ]]
do
    if [[ $N -lt 0 ]] ; then
        echo "Platform deployment timeout."        
        exit 1
    fi
    echo "Waiting for platform deployment to complete"
    sleep 5
    N=$N-5
    PLATFORM_READY=$(kubectl get dss -n $KPLAT_NAMESPACE platform-deployment -o=jsonpath="{$.status.conditions[?(@.type=='Ready')].status}" || echo "False")
done

echo "Deployment completed"
