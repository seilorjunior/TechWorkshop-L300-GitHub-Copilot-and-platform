@description('Name of the Azure AI Services account')
param name string

@description('Location for the Azure AI Services account')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU for the Azure AI Services account')
param sku object = {
  name: 'S0'
}

@description('Kind of Cognitive Services account')
param kind string = 'AIServices'

resource cognitiveService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// Deploy GPT-4 model
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: cognitiveService
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
  }
}

// Deploy Phi model (if available in westus3)
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: cognitiveService
  name: 'phi-3'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'phi-3'
      version: 'latest'
    }
  }
  dependsOn: [
    gpt4Deployment
  ]
}

output id string = cognitiveService.id
output name string = cognitiveService.name
output endpoint string = cognitiveService.properties.endpoint
output key string = cognitiveService.listKeys().key1
