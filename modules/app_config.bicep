@description('Name of the App Configuration Store')
param appConfigName string


resource appConfig 'Microsoft.AppConfiguration/configurationStores@2025-02-01-preview' = {
  name: appConfigName
  location: 'eastus'
  sku: {
    name: 'free'
  }
  properties: {
    encryption: {}
    disableLocalAuth: true
    softDeleteRetentionInDays: 0
    defaultKeyValueRevisionRetentionPeriodInSeconds: 604800
    enablePurgeProtection: false
    dataPlaneProxy: {
      authenticationMode: 'Pass-through'
      privateLinkDelegation: 'Disabled'
    }
    telemetry: {}
  }
}

output appConfigEnpoint string = appConfig.properties.endpoint
output appConfigName string = appConfig.name

