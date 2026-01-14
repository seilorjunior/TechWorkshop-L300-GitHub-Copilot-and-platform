// Azure AI Services (Microsoft Foundry)

@description('Name of the AI Services resource')
param name string

@description('Location for the resource')
param location string

@description('Tags for the resource')
param tags object = {}

@description('SKU for AI Services')
@allowed(['S0'])
param sku string = 'S0'

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: toLower(name)
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    disableLocalAuth: true
  }
}

output id string = aiServices.id
output name string = aiServices.name
output endpoint string = aiServices.properties.endpoint
