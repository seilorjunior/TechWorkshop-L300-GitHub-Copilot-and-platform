// App Service Plan (Linux)

@description('Name of the App Service Plan')
param name string

@description('Location for the plan')
param location string

@description('Tags for the resource')
param tags object = {}

@description('SKU for the App Service Plan')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1v2', 'P2v2', 'P3v2'])
param sku string = 'B1'

@description('Is this a Linux plan (true) or Windows (false)')
param reserved bool = true

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: reserved ? 'linux' : 'windows'
  sku: {
    name: sku
    capacity: 1
  }
  properties: {
    reserved: reserved // Required: true for Linux, false for Windows
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    zoneRedundant: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
