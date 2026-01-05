using '../../main.bicep'

param environmentName = 'prod'
param location = 'eastus'

// Optional overrides (leave empty to auto-generate)
param resourceGroupName = 'rg-prod-python'
param functionPlanName = 'plan-prod'
param functionAppName = 'v-prod-python'
param storageAccountName = 'vstorageprod'
param logAnalyticsName = 'vla-prod'
param applicationInsightsName = 'vapp-prod'

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
