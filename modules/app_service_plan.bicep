@description('Location for the App Service Plan')
param location string

@description('Name of the App Service Plan')
@minLength(1)
@maxLength(40)
param appServicePlanName string

@description('Tags to apply to the App Service Plan')
param tags object = {}

@description('Enable zone redundancy (only supported in certain regions)')
param zoneRedundant bool = false

resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  tags: tags
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true               // Required for Linux
    zoneRedundant: zoneRedundant // Optional, region dependent
  }
}

output name string = plan.name
output resourceId string = plan.id
