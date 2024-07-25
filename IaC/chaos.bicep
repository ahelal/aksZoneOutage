targetScope='subscription'


param resourceGroupName string
param vmssName string
param location string

module chaos './modules/chaos-module.bicep' = {
  name: 'chaos'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    experimentName: 'akszoneoutage'
    targetName: vmssName
  }
}
