@description('Name of the Application Insights resource')
param name string

@description('Location for the Application Insights resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('Application type')
param kind string = 'web'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${name}-workspace'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    Application_Type: kind
    WorkspaceResourceId: logAnalyticsWorkspace.id
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}

output id string = appInsights.id
output name string = appInsights.name
output connectionString string = appInsights.properties.ConnectionString
output instrumentationKey string = appInsights.properties.InstrumentationKey
