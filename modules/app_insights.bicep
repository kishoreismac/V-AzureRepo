@description('Location for Application Insights')
param location string

@description('Application Insights resource name')
@minLength(1)
@maxLength(260)
param applicationInsightsName string

@description('Tags to apply')
param tags object = {}

@description('Resource Id of the Log Analytics Workspace (workspace-based App Insights)')
param workspaceResourceId string

@description('Disable local authentication (recommended). When true, blocks API key/local auth patterns.')
param disableLocalAuth bool = true

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceResourceId
    DisableLocalAuth: disableLocalAuth
  }
}

output name string = appi.name
output resourceId string = appi.id
output connectionString string = appi.properties.ConnectionString
output instrumentationKey string = appi.properties.InstrumentationKey
