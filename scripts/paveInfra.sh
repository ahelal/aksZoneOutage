#!/bin/bash

set -e
set -o pipefail

# Repo origination structure
DIR="$( cd "$( dirname "$0" )" && pwd )"
COMMON_FILE="${DIR}/_common.sh"

# Load common
source "${COMMON_FILE}"

aks_up(){
    echo "***** CREATING AKS *****"
    az deployment sub create \
        --name "paveAKS" \
        --template-file aks.bicep \
        --location "${location}" \
        --parameters location="${location}" \
        --parameters resourceGroupName="${resourceGroupName}" | tee "${statusFile}"
}

aks_workload_deploy(){
    aksGetCreds
    kubectl apply -f "${DIR}/../workload/workload.yaml"
    echo "Waiting for external IP to be assigned to nginx service..."
    sleep 30
    ip=$(kubectl get svc nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "IP: ${ip}"
    echo "Call http://${ip}/zone.html"
}

aks_workload_watch(){
    aksGetCreds
    kubectl get pods -owide -w
}

chaos_up(){
    # fetch node resource group and VMSS name from output of previous deployment
    export nodeResourceGroup=$(_parseJson "['properties']['outputs']['deploymentScriptOutput']['value']['nodeResourceGroup']")
    export aksVMSS=$(_parseJson "['properties']['outputs']['deploymentScriptOutput']['value']['VMSS']")

    echo "***** CREATING Chaos studio *****" 
    az deployment sub create \
        --name "paveChaos" \
        --template-file chaos.bicep \
        --location "${location}" \
        --parameters vmssName="${aksVMSS}" \
        --parameters location="${location}" \
        --parameters resourceGroupName="${nodeResourceGroup}"
}

chaos_start(){
    export nodeResourceGroup=$(_parseJson "['properties']['outputs']['deploymentScriptOutput']['value']['nodeResourceGroup']")
    export subscriptionId=$(_parseJson "['properties']['outputs']['subscriptionId']['value']")
    echo "***** STARTING Chaos Experiment *****"
    az rest --method post \
        --uri "https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${nodeResourceGroup}/providers/Microsoft.Chaos/experiments/akszoneoutage/start?api-version=2023-11-01"
    echo "***** Chaos experiment started *****"
}

chaos_stop(){
    export nodeResourceGroup=$(_parseJson "['properties']['outputs']['deploymentScriptOutput']['value']['nodeResourceGroup']")
    export subscriptionId=$(_parseJson "['properties']['outputs']['subscriptionId']['value']")
    echo "***** STOPPING Chaos Experiment *****"
    az rest --method post \
        --uri "https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${nodeResourceGroup}/providers/Microsoft.Chaos/experiments/akszoneoutage/cancel?api-version=2023-11-01"
    echo "***** Chaos experiment stopped *****"
}

## Main
if [ "$1" == "up" ]; then
    aks_up
    chaos_up

elif [ "$1" == "start" ]; then
    chaos_start

elif [ "$1" == "stop" ]; then
    chaos_stop

elif [ "$1" == "down" ] || [ "$1" == "delete" ] ; then
    echo "***** DELETING Resource Group *****"
    az group delete --name "${resourceGroupName}" --yes
    rm -rf "${statusFile}"

elif [ "$1" == "aks-creds" ]; then
    aksGetCreds

elif [ "$1" == "watch" ]; then
    aks_workload_watch

elif [ "$1" == "deploy" ]; then
    aks_workload_deploy
else
    echo "Argumants not supported '${1}'."
    echo "Supported arguments:" 
    echo "   up\t\t\t : Bring up the azure infrastructure"
    echo "   down\t\t\t : Delete the infrastructure"
    echo "   deploy\t\t : Deploy test nginx workload"
    echo "   start\t\t : Start the chaos experiment"
    echo "   stop\t\t\t : Stop the chaos experiment"
    echo "   watch\t\t : Watch the workload"
    echo "   aks-creds\t\t : Get AKS credentials"
    exit 1
fi
