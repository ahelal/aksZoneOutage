
targetScope='subscription'

@description('AKS resource group name')
param resourceGroupName string

@description('Resource location')
param location string

@minLength(4)
@description('Unique postfix for resources')
param postfix string = uniqueString('${subscription()}-${location}')

@description('AKS node count')
param nodeCount int = 3

@description('AKS node SKU')
param nodeSku string = 'Standard_B4ms'

var version = '0.1.0'
var clusterName = 'akszoneoutage${postfix}'
var acrName = 'acr${postfix}'
var tags ={
    deployment:'akszoneoutage'
    managedBy: 'Bicep'
    version: version
}

module rGroup 'br/public:avm/res/resources/resource-group:0.2.4' = {
  name: 'resourceGroupDeployment'
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}

module acr 'br/public:avm/res/container-registry/registry:0.3.2' = {
  name: '${uniqueString(deployment().name, resourceGroupName)}-acr'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rGroup, aks]
  params: {
    name: acrName
    location: location
    roleAssignments: [
      {
        principalId: aks.outputs.kubeletIdentityObjectId
        roleDefinitionIdOrName: 'AcrPull'
        principalType: 'ServicePrincipal'
      }
    ]
    tags: tags
  }
}

module aks 'br/public:avm/res/container-service/managed-cluster:0.1.7' = {
  name: '${uniqueString(deployment().name, rGroup.name)}-aks'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rGroup]
  params: {
    name: clusterName
    publicNetworkAccess: 'Enabled'
    primaryAgentPoolProfile: [
      {
        count: nodeCount
        mode: 'System'
        name: 'mainpool'
        vmSize: nodeSku
        osSKU: 'AzureLinux'
        availabilityZones: [ '1', '2', '3' ]
      }
    ]
    location: location
    managedIdentities: {
      systemAssigned: true
    }
    networkPlugin: 'kubenet'
    tags: tags
  }
}

@description('The Contributor Role definition from [Built In Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles).')
resource contriubtorRoleDef 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

module scriptIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.2' = {
  name: 'userAssignedIdentityDeployment'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rGroup]
  params: {
    name: 'scriptIdentity'
    location: location
  }
}

module roleAssignment './modules/rgAssignment-module.bicep' = {
  name: 'roleAssignment'
  dependsOn: [scriptIdentity]
  params: {
    principalId:  scriptIdentity.outputs.principalId
    roleDefinitionId: contriubtorRoleDef.id
    scriptIdentityId: scriptIdentity.outputs.clientId
  }
}

module deploymentScript 'br/public:avm/res/resources/deployment-script:0.2.4' = {
  name: 'script'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [roleAssignment]
  params: {
    kind: 'AzureCLI'
    name: 'script'
    azCliVersion: '2.59.0'
    managedIdentities: {
      userAssignedResourcesIds: [scriptIdentity.outputs.resourceId]
    }
    retentionInterval: 'PT1H'
    arguments: '${clusterName} ${resourceGroupName}'
    scriptContent:'''
    #!/bin/bash
    set -ex
    export managedClusterName="${1}"
    export resourceGroupName="${2}"

    export nodeResourceGroup=$(az aks show --name ${managedClusterName} --resource-group ${resourceGroupName} --query nodeResourceGroup --output tsv)
    export VMSS="$(az resource list --resource-type 'Microsoft.Compute/virtualMachineScaleSets' --resource-group ${nodeResourceGroup} --query '[].name' --output tsv)"
    echo "{ \"VMSS\" : \"${VMSS}\", \"nodeResourceGroup\" : \"${nodeResourceGroup}\" }" > $AZ_SCRIPTS_OUTPUT_PATH
  '''
  }
}

output deploymentScriptLogs string[] = deploymentScript.outputs.deploymentScriptLogs
output deploymentScriptOutput object = deploymentScript.outputs.outputs
output resourceGroup string = resourceGroupName
output acrName string  = acrName
output aksFQDN string  = aks.outputs.controlPlaneFQDN
output aksName string  = clusterName
output subscriptionId string = subscription().subscriptionId
