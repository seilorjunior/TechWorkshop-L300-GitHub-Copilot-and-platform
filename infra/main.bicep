// Azure Infrastructure for ZavaStorefront Application
// Dev environment deployment using AZD

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = 'westus3'

// Optional parameters
@description('Name of the resource group')
param resourceGroupName string = ''

@description('SKU for the Azure Container Registry')
@allowed(['Basic', 'Standard', 'Premium'])
param acrSku string = 'Basic'

@description('SKU for the App Service Plan')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1v2', 'P2v2', 'P3v2'])
param appServicePlanSku string = 'B1'

// Generate unique resource token
var resourceToken = uniqueString(subscription().id, location, environmentName)
var abbrs = loadJsonContent('./abbreviations.json')
var tags = {
  'azd-env-name': environmentName
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : 'rg-${environmentName}'
  location: location
  tags: tags
}

// User Assigned Managed Identity
module userAssignedIdentity 'modules/identity.bicep' = {
  name: 'userAssignedIdentity'
  scope: rg
  params: {
    name: '${abbrs.managedIdentity}${resourceToken}'
    location: location
    tags: tags
  }
}

// Log Analytics Workspace
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'logAnalytics'
  scope: rg
  params: {
    name: '${abbrs.logAnalytics}${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights
module applicationInsights 'modules/app-insights.bicep' = {
  name: 'applicationInsights'
  scope: rg
  params: {
    name: '${abbrs.appInsights}${resourceToken}'
    location: location
    tags: tags
    workspaceId: logAnalytics.outputs.id
  }
}

// Azure Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  scope: rg
  params: {
    name: '${abbrs.containerRegistry}${resourceToken}'
    location: location
    tags: tags
    sku: acrSku
  }
}

// App Service Plan (Linux)
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlan'
  scope: rg
  params: {
    name: '${abbrs.appServicePlan}${resourceToken}'
    location: location
    tags: tags
    sku: appServicePlanSku
    reserved: true // Linux
  }
}

// Web App for Containers
module webApp 'modules/web-app.bicep' = {
  name: 'webApp'
  scope: rg
  params: {
    name: '${abbrs.webApp}${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
    appServicePlanId: appServicePlan.outputs.id
    userAssignedIdentityId: userAssignedIdentity.outputs.id
    userAssignedIdentityClientId: userAssignedIdentity.outputs.clientId
    containerRegistryName: containerRegistry.outputs.name
    applicationInsightsConnectionString: applicationInsights.outputs.connectionString
    applicationInsightsInstrumentationKey: applicationInsights.outputs.instrumentationKey
  }
}

// ACR Pull Role Assignment for Web App
module acrPullRoleAssignment 'modules/role-assignment-acr.bicep' = {
  name: 'acrPullRoleAssignment'
  scope: rg
  params: {
    containerRegistryName: containerRegistry.outputs.name
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Azure AI Services (Foundry) for GPT-4 and Phi models
module aiServices 'modules/ai-services.bicep' = {
  name: 'aiServices'
  scope: rg
  params: {
    name: '${abbrs.aiServices}${resourceToken}'
    location: location
    tags: tags
  }
}

// Diagnostic Settings for Web App
module webAppDiagnostics 'modules/diagnostic-settings.bicep' = {
  name: 'webAppDiagnostics'
  scope: rg
  params: {
    name: 'diag-${abbrs.webApp}${resourceToken}'
    webAppName: webApp.outputs.name
    workspaceId: logAnalytics.outputs.id
  }
}

// Diagnostic Settings for AI Services
module aiServicesDiagnostics 'modules/diagnostic-settings-ai-services.bicep' = {
  name: 'aiServicesDiagnostics'
  scope: rg
  params: {
    name: 'diag-${abbrs.aiServices}${resourceToken}'
    aiServicesName: aiServices.outputs.name
    workspaceId: logAnalytics.outputs.id
  }
}

// Outputs
output RESOURCE_GROUP_ID string = rg.id
output RESOURCE_GROUP_NAME string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output WEB_APP_NAME string = webApp.outputs.name
output WEB_APP_URL string = webApp.outputs.url
output APPLICATION_INSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
output AI_SERVICES_ENDPOINT string = aiServices.outputs.endpoint
output USER_ASSIGNED_IDENTITY_ID string = userAssignedIdentity.outputs.id
