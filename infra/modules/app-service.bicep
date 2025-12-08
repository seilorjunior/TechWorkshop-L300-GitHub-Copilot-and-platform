@description('Name of the App Service')
param name string

@description('Location for the App Service')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('App Service Plan ID')
param appServicePlanId string

@description('Azure Container Registry name')
param acrName string

@description('Azure Container Registry login server')
param acrLoginServer string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('Docker image name')
param dockerImageName string = 'zavastorefrontapp'

@description('Docker image tag')
param dockerImageTag string = 'latest'

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${dockerImageName}:${dockerImageTag}'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
      ]
    }
  }
}

output id string = appService.id
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output identityPrincipalId string = appService.identity.principalId
