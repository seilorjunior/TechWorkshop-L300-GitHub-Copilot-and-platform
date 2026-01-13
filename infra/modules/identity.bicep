// User Assigned Managed Identity

@description('Name of the managed identity')
param name string

@description('Location for the managed identity')
param location string

@description('Tags for the resource')
param tags object = {}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

output id string = userAssignedIdentity.id
output principalId string = userAssignedIdentity.properties.principalId
output clientId string = userAssignedIdentity.properties.clientId
output name string = userAssignedIdentity.name
