#!/bin/sh
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

## Main
if [ "$1" == "up" ]; then
    aks_up
    chaos_up

elif [ "$1" == "down" ] || [ "$1" == "delete" ] ; then
    echo "***** DELETING Resource Group *****"
    az group delete --name "${resourceGroupName}" --yes
    rm -rf "${statusFile}"

elif [ "$1" == "aks-creds" ]; then
    aksGetCreds

else
    echo "Argumants not supported '${1}'."
    echo "Supported arguments are" 
    echo "   up\t\t\t : Bring up the azure infrastructure"
    echo "   down\t\t\t : Dlete the infrastructure"
    echo "   deploy\t\t : Deploy test nginx workload"
    echo "   aks-creds\t\t : Get AKS credentials"
    exit 1
fi
