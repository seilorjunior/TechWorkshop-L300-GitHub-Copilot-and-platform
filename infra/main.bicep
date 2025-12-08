targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (dev, staging, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = 'westus3'

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Tags to apply to all resources')
param tags object = {}

// Generate a unique token for resource naming
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}-${resourceToken}'
  location: location
  tags: union(tags, {
    'azd-env-name': environmentName
  })
}

// Container Registry
module acr './modules/acr.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights
module appInsights './modules/app-insights.bicep' = {
  name: 'app-insights'
  scope: rg
  params: {
    name: '${abbrs.insightsComponents}${resourceToken}'
    location: location
    tags: tags
  }
}

// App Service Plan
module appServicePlan './modules/app-service-plan.bicep' = {
  name: 'app-service-plan'
  scope: rg
  params: {
    name: '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'B1'
      tier: 'Basic'
    }
    kind: 'linux'
    reserved: true
  }
}

// App Service
module appService './modules/app-service.bicep' = {
  name: 'app-service'
  scope: rg
  params: {
    name: '${abbrs.webSitesAppService}${resourceToken}'
    location: location
    tags: union(tags, {
      'azd-service-name': 'web'
    })
    appServicePlanId: appServicePlan.outputs.id
    acrName: acr.outputs.name
    acrLoginServer: acr.outputs.loginServer
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
  }
}

// Azure AI Foundry (Azure OpenAI or AI Services)
module aiFoundry './modules/ai-foundry.bicep' = {
  name: 'ai-foundry'
  scope: rg
  params: {
    name: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'S0'
    }
  }
}

// Role assignment for App Service to pull from ACR
module acrRoleAssignment './modules/acr-role-assignment.bicep' = {
  name: 'acr-role-assignment'
  scope: rg
  params: {
    acrName: acr.outputs.name
    principalId: appService.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output AZURE_APP_SERVICE_NAME string = appService.outputs.name
output AZURE_APP_SERVICE_URL string = appService.outputs.uri
output AZURE_AI_FOUNDRY_ENDPOINT string = aiFoundry.outputs.endpoint
output AZURE_AI_FOUNDRY_NAME string = aiFoundry.outputs.name
