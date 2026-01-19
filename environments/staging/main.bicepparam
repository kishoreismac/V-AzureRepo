using '../../main.bicep'

param environmentName = 'staging'
param location = 'eastus'

// Optional overrides (leave empty to auto-generate)
param resourceGroupName = 'rg-vsamplepython-staging'
param appConfigName = 'appconfig-vsample-staging'
param keyVaultName = 'kv-vsample-staging'
param functionPlanName = 'plan-staging'
param functionAppName = 'v-sample-python-staging'
param storageAccountName = 'vstoragesamplestg'
param logAnalyticsName = 'v-la-sample-staging'
param applicationInsightsName = 'v-appins-sample-staging'

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
