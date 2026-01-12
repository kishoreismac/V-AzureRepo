using '../../main.bicep'

param environmentName = 'dev'
param location = 'eastus'

// Optional overrides (leave empty to auto-generate)
param resourceGroupName = 'rg-vsamplepython-dev'
param appConfigName = 'appconfig-vsample-dev'
param keyVaultName = 'kv-vsample-dev'
param functionPlanName = 'plan-dev'
param functionAppName = 'v-sample-python-dev'
param storageAccountName = 'vstoragesampledev'
param logAnalyticsName = 'v-la-sample-dev'
param applicationInsightsName = 'v-appins-sample-dev'

// Function runtime configuration
param functionAppRuntime = 'python'
param functionAppRuntimeVersion = '3.11'

// Flex Consumption scaling configuration
param maximumInstanceCount = 100
param instanceMemoryMB = 2048

// Zone redundancy (enable only if region supports it)
param zoneRedundant = false

// Optional: user objectId for dev/test access (leave empty for prod)
param principalId = ''

param servicePrincipalId =  '92af43c1-4683-4d2b-a014-ae6d79797454'
