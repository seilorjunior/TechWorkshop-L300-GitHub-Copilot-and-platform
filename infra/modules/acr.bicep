@description('Name of the Azure Container Registry')
param name string

@description('Location for the Azure Container Registry')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU for the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // Use RBAC instead of admin credentials
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}

output id string = acr.id
output name string = acr.name
output loginServer string = acr.properties.loginServer
