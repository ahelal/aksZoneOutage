if ! [ -z "${DEBUG}" ]; then
    set -x
fi

# Repo origination structure
DIR="$( cd "$( dirname "$0" )" && pwd )"
INFRA_DIR="$DIR/../IaC"

statusFile="${INFRA_DIR}/.aks.status.json"
# paramFile="main.bicepparam"
configFile="${INFRA_DIR}/../config.env"
# versionFile="${INFRA_DIR}/../version.json"

cd $INFRA_DIR

# Load config
source "${configFile}"

aksGetCreds(){
    AKS_NAME="$(_parseJson "['properties']['outputs']['aksName']['value']")"
    RG="$(_parseJson "['properties']['outputs']['resourceGroup']['value']")"
    echo "Getting AKS creds for ${AKS_NAME} in RG: ${RG}"

    az aks get-credentials \
        --resource-group "${RG}" \
        --name "${AKS_NAME}" \
        --admin
    echo "> Getting nodes ..."
    kubectl get nodes
}

_parseJson(){
    if ! [ -f  "${statusFile}" ] ; then
        echo "Status file '${statusFile}' not found"
        exit 1
    fi
    cat ${statusFile} | python3 -c "import sys, json; print(json.load(sys.stdin)${1})"
}
