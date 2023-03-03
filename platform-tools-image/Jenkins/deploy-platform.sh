#!/usr/bin/env bash

set -e 

#trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

KPLAT_RELEASE_NAME=${KPLAT_RELEASE_NAME:-"k8s-platform"}
KPLAT_NAMESPACE=${KPLAT_NAMESPACE:-"platform"}
KPLAT_REPO=${KPLAT_REPO:-"https://artifactory.qvantel.net/artifactory/all-helm/"}
KPLAT_CHART=${KPLAT_CHART:-"k8s-platform-addon-operator"}
KPLAT_CHART_VERSION=${KPLAT_CHART_VERSION:-""}
HELM_VALUES=${HELM_VALUES:-""}
HELM_SET=${HELM_SET:-""}
TIMEOUT=${TIMEOUT:-"600s"}


# Here we deploy platform helm chart with custom configuration from myvalues.yaml and also instruct it to use our locally built image
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [[ -n $KPLAT_CHART_VERSION ]] ; then
    helm upgrade --install $KPLAT_RELEASE_NAME -n $KPLAT_NAMESPACE --create-namespace \
        --repo $KPLAT_REPO --version $KPLAT_CHART_VERSION $KPLAT_CHART $HELM_VALUES $HELM_SET
else
    helm upgrade --install $KPLAT_RELEASE_NAME -n $KPLAT_NAMESPACE --create-namespace \
        --repo $KPLAT_REPO $KPLAT_CHART $HELM_VALUES $HELM_SET
fi

sleep 5
echo "Waiting for addon-operator pod to be available"
kubectl wait deployment addon-operator -n $KPLAT_NAMESPACE --for condition=Available=True --timeout=$TIMEOUT
ADDON_OPERATOR_POD=$(kubectl get pod -n $KPLAT_NAMESPACE -l app=addon-operator -o jsonpath="{.items[0].metadata.name}")
echo "$ADDON_OPERATOR_POD"

echo "Waiting for addon-operator deployement to start"
until kubectl wait --for=condition=ready=false dss -n $KPLAT_NAMESPACE platform-deployment --timeout=5s
do
    if kubectl wait --for=condition=ready=true dss -n $KPLAT_NAMESPACE platform-deployment --timeout=1s ; then 
        echo "Deployment already in the ready state. Exiting"
        kubectl logs $ADDON_OPERATOR_POD -n $KPLAT_NAMESPACE --since-time=$START_TIME  
        exit 1 
    else
        echo "No deployment status or deployemnt is not yet triggered. Repeat waiting"
        sleep 1 
    fi    
done

echo "Deployment started"

sleep 5

kubectl get dss -n $KPLAT_NAMESPACE platform-deployment

echo "Waiting for addon-operator deployement to complete"

kubectl logs $ADDON_OPERATOR_POD -n $KPLAT_NAMESPACE -f --since-time=$START_TIME &

kubectl wait --for=condition=ready dss -n $KPLAT_NAMESPACE platform-deployment --timeout=$TIMEOUT

echo "Deployment completed"