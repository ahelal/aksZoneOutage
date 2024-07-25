@description('The existing vmsss resource you want to target in this experiment')
param targetName string

@description('Desired name for your Chaos Experiment')
param experimentName string

@description('Desired region for the experiment, targets, and capabilities')
param location string = resourceGroup().location

// Define Chaos Studio experiment steps
param experimentSteps array = [
  {
    name: 'Step 1'
    branches: [
        {
            name: 'Branch1'
            actions: [
                {
                    name: 'urn:csci:microsoft:virtualMachineScaleSet:shutdown/2.0'
                    type: 'continuous'
                    selectorId: 'Selector1'
                    duration: 'PT10M'
                    parameters: [
                        {
                            key: 'abruptShutdown'
                            value: 'true'
                        }
                    ]
                }
            ]
        }
    ]
  }
]

// Reference the existing VMSS
resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' existing = {
  name: targetName
}

// Deploy the Chaos Studio target resource to the VMSS
resource chaosTarget 'Microsoft.Chaos/targets@2024-01-01' = {
  name: 'Microsoft-VirtualMachineScaleSet'
  location: location
  scope: vmss
  properties: {}
  // Define the capability VMSS Shutdown
  resource chaosCapability 'capabilities' = {
    name: 'Shutdown-2.0'
  }
}

// Define the role definition for the Chaos experiment
resource chaosRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  // Contributor role -- see https://learn.microsoft.com/azure/role-based-access-control/built-in-roles 
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

// Define the role assignment for the Chaos experiment
resource chaosRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vmss.id, chaosExperiment.id, chaosRoleDefinition.id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: chaosRoleDefinition.id
    principalId: chaosExperiment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deploy the Chaos Studio experiment resource
resource chaosExperiment 'Microsoft.Chaos/experiments@2024-01-01' = {
  name: experimentName
  location: location // Doesn't need to be the same as the Targets & Capabilities location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    selectors: [
      {
        id: 'Selector1'
        type: 'List'
        targets: [
          {
            id: chaosTarget.id
            type: 'ChaosTarget'
          }
        ]
        filter: {
          type: 'Simple'
          parameters: {
              zones: [
                  '1'
              ]
          }
        }
      }
    ]
    steps: experimentSteps
  }
}
