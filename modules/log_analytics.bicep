@description('Location for the Log Analytics workspace')
param location string

@description('Name of the Log Analytics workspace')
@minLength(4)
@maxLength(63)
param logAnalyticsName string

@description('Tags to apply to the workspace')
param tags object = {}

@description('Workspace retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('SKU for Log Analytics workspace')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
])
param skuName string = 'PerGB2018'

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output name string = law.name
output resourceId string = law.id
output customerId string = law.properties.customerId
