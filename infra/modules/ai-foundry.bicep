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

@description('Deploy GPT-4 model')
param deployGpt4 bool = true

@description('GPT-4 model version')
param gpt4Version string = '1106-Preview'

@description('Deploy Phi-3 model')
param deployPhi3 bool = true

@description('Phi-3 model version')
param phi3Version string = 'mini-4k-instruct'

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

// Deploy GPT-4 model (conditional)
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployGpt4) {
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
      version: gpt4Version
    }
  }
}

// Deploy Phi-3 model (conditional)
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployPhi3) {
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
      version: phi3Version
    }
  }
  dependsOn: [
    gpt4Deployment
  ]
}

output id string = cognitiveService.id
output name string = cognitiveService.name
output endpoint string = cognitiveService.properties.endpoint
