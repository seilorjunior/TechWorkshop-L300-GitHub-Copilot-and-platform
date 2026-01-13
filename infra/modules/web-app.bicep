// Web App for Containers

@description('Name of the Web App')
param name string

@description('Location for the app')
param location string

@description('Tags for the resource')
param tags object = {}

@description('App Service Plan ID')
param appServicePlanId string

@description('User Assigned Identity resource ID')
param userAssignedIdentityId string

@description('User Assigned Identity Client ID')
param userAssignedIdentityClientId string

@description('Container Registry name')
param containerRegistryName string

@description('Application Insights connection string')
param applicationInsightsConnectionString string

@description('Application Insights instrumentation key')
param applicationInsightsInstrumentationKey string

@description('Docker image and tag')
param dockerImageAndTag string = 'mcr.microsoft.com/appsvc/staticsite:latest'

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    reserved: true
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImageAndTag}'
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      http20Enabled: true
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: userAssignedIdentityClientId
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryName}.azurecr.io'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsightsInstrumentationKey
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
    }
    clientAffinityEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output id string = webApp.id
output name string = webApp.name
output url string = 'https://${webApp.properties.defaultHostName}'
output principalId string = webApp.identity.userAssignedIdentities[userAssignedIdentityId].principalId
