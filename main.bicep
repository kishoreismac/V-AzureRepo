targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment used to generate a short unique hash used in all resources.')
param environmentName string

@metadata({
  azd: {
    type: 'location'
  }
})
param location string

@description('Optional: Provide an existing resource group name. If empty, a name will be generated.')
param resourceGroupName string = ''

@description('Optional: Provide an existing Function App plan name. If empty, a name will be generated.')
param functionPlanName string = ''

@description('Optional: Provide an existing Function App name. If empty, a name will be generated.')
param functionAppName string = ''

@description('Optional: Provide an existing Storage Account name. If empty, a name will be generated.')
param storageAccountName string = ''

@description('Optional: Provide an existing Log Analytics name. If empty, a name will be generated.')
param logAnalyticsName string = ''

@description('Optional: Provide an existing App Insights name. If empty, a name will be generated.')
param applicationInsightsName string = ''

@allowed(['dotnet-isolated','python','java','node','powerShell'])
param functionAppRuntime string = 'python'

@allowed(['3.10','3.11','3.12','7.4','8.0','9.0','10','11','17','20','21','22'])
param functionAppRuntimeVersion string = '3.11'

@minValue(40)
@maxValue(1000)
param maximumInstanceCount int = 100

@allowed([512,2048,4096])
param instanceMemoryMB int = 2048

@description('Enable zone redundancy (only supported in some regions).')
param zoneRedundant bool = false

@description('Id of the user running this template (dev/test). Leave empty if not needed.')
param principalId string = ''

// ----------------------------
// Naming + Tags
// ----------------------------
var abbrs = loadJsonContent('./abbreviations.json')

// token used for uniqueness (keep short for storage accounts)
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var shortToken = take(resourceToken, 18) // storage max 24 chars -> "st" + 18 = 20 safe

var rgName_resolved = !empty(resourceGroupName)
  ? resourceGroupName
  : '${abbrs.resourcesResourceGroups}${environmentName}'

var functionAppName_resolved = !empty(functionAppName)
  ? functionAppName
  : '${abbrs.webSitesFunctions}${resourceToken}' // function apps allow longer names

var functionPlanName_resolved = !empty(functionPlanName)
  ? functionPlanName
  : '${abbrs.webServerFarms}${environmentName}-${take(resourceToken, 8)}' // readable + unique

// Storage Account must be lowercase + 3-24 chars, no hyphens.
// Your abbr is "st" which is good. Keep token short.
var storageAccountName_resolved = !empty(storageAccountName)
  ? toLower(replace(storageAccountName, '-', ''))
  : toLower('${abbrs.storageStorageAccounts}${shortToken}')

var logAnalyticsName_resolved = !empty(logAnalyticsName)
  ? logAnalyticsName
  : '${abbrs.operationalInsightsWorkspaces}${environmentName}-${take(resourceToken, 8)}'

var applicationInsightsName_resolved = !empty(applicationInsightsName)
  ? applicationInsightsName
  : '${abbrs.insightsComponents}${environmentName}-${take(resourceToken, 8)}'

// Deployment container name: <= 63 chars, lowercase recommended
var deploymentStorageContainerName = toLower('app-package-${take(functionAppName_resolved, 32)}-${take(resourceToken, 7)}')

var tags = {
  'azd-env-name': environmentName
}

// ----------------------------
// Resource Group (subscription-scope)
// ----------------------------
resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName_resolved
  location: location
  tags: tags
}

// ----------------------------
// Log Analytics (module)
// ----------------------------
module logAnalytics 'modules/log_analytics.bicep' = {
  name: 'loganalytics'
  scope: rg
  params: {
    location: location
    logAnalyticsName: logAnalyticsName_resolved
    tags: tags
    retentionInDays: 30
    skuName: 'PerGB2018'
  }
}

// ----------------------------
// Application Insights (module) - workspace-based
// ----------------------------
module applicationInsights 'modules/app_insights.bicep' = {
  name: 'appinsights'
  scope: rg
  params: {
    location: location
    applicationInsightsName: applicationInsightsName_resolved
    tags: tags
    workspaceResourceId: logAnalytics.outputs.resourceId
    disableLocalAuth: true
  }
}

// ----------------------------
// Storage Account (module)
// ----------------------------
module storage 'modules/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    location: location
    storageAccountName: storageAccountName_resolved
    tags: tags
    deploymentContainerName: deploymentStorageContainerName
  }
}

var deploymentBlobContainerUri = '${storage.outputs.blobEndpoint}${deploymentStorageContainerName}'

// ----------------------------
// App Service Plan (module) - Flex Consumption FC1
// ----------------------------
module appServicePlan 'modules/app_service_plan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    location: location
    appServicePlanName: functionPlanName_resolved
    tags: tags
    zoneRedundant: zoneRedundant
  }
}

// ----------------------------
// Function App (module) - Linux + Flex Consumption
// ----------------------------
module functionApp 'modules/function_app.bicep' = {
  name: 'functionapp'
  scope: rg
  params: {
    location: location
    functionAppName: functionAppName_resolved
    serverFarmResourceId: appServicePlan.outputs.resourceId
    storageAccountName: storage.outputs.name
    deploymentBlobContainerUri: deploymentBlobContainerUri
    appInsightsConnectionString: applicationInsights.outputs.connectionString
    tags: union(tags, { 'azd-service-name': 'api' })

    functionAppRuntime: functionAppRuntime
    functionAppRuntimeVersion: functionAppRuntimeVersion
    maximumInstanceCount: maximumInstanceCount
    instanceMemoryMB: instanceMemoryMB

  }
}

// ----------------------------
// RBAC (native resources module)
// ----------------------------
module rbacAssignments 'modules/rbac.bicep' = {
  name: 'rbacAssignments'
  scope: rg
  params: {
    storageAccountName: storage.outputs.name
    appInsightsName: applicationInsights.outputs.name
    managedIdentityPrincipalId: functionApp.outputs.principalId

    userIdentityPrincipalId: principalId
    allowUserIdentityPrincipal: !empty(principalId)
  }
}

// ----------------------------
// Outputs
// ----------------------------
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output RESOURCE_GROUP_NAME string = rg.name
output STORAGE_ACCOUNT_NAME string = storage.outputs.name
output LOG_ANALYTICS_NAME string = logAnalytics.outputs.name
output APPLICATION_INSIGHTS_NAME string = applicationInsights.outputs.name
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
output AZURE_FUNCTION_NAME string = functionApp.outputs.name
output FUNCTION_IDENTITY_PRINCIPAL_ID string = functionApp.outputs.principalId
output DEPLOYMENT_BLOB_CONTAINER_URI string = deploymentBlobContainerUri
