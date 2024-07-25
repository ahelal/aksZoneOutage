targetScope = 'subscription'

param scriptIdentityId string
param principalId string
param roleDefinitionId string

@description('Assign permission for the deployment scripts user identity access to the subscription')
resource contriubutrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: subscription()
  name: guid(roleDefinitionId, scriptIdentityId, subscription().id)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: principalId
    roleDefinitionId: roleDefinitionId
  }
}
