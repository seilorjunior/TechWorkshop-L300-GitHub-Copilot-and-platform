// AI Services Role Assignment for Managed Identity

@description('Name of the AI Services account')
param aiServicesName string

@description('Principal ID to assign the role to')
param principalId string

@description('Principal type')
@allowed(['ServicePrincipal', 'User', 'Group'])
param principalType string = 'ServicePrincipal'

// Built-in role definition ID for "Cognitive Services User"
// This role allows access to read and list keys of Cognitive Services
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: aiServicesName
}

resource cognitiveServicesUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServices.id, principalId, cognitiveServicesUserRoleDefinitionId)
  scope: aiServices
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

output id string = cognitiveServicesUserRoleAssignment.id
