// RBAC Role Assignments (native resources)
// Assign required permissions to Function App system-assigned managed identity
// and optionally to a user identity for dev/testing.

param storageAccountName string
param appInsightsName string
param managedIdentityPrincipalId string
param userIdentityPrincipalId string = ''
param allowUserIdentityPrincipal bool = false

// Built-in role definition IDs
var roleDefinitions = {
  storageBlobDataOwner: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
  storageQueueDataContributor: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
  storageTableDataContributor: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
  monitoringMetricsPublisher: '3913510d-42f4-4e42-8a64-420c390055eb'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

var storageScopeId = storageAccount.id
var appInsightsScopeId = applicationInsights.id

// Helper: role definition resource IDs (must be fully-qualified)
var storageBlobDataOwnerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storageBlobDataOwner)
var storageQueueDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storageQueueDataContributor)
var storageTableDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storageTableDataContributor)
var monitoringMetricsPublisherRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.monitoringMetricsPublisher)

//
// -------- Storage RBAC for System-Assigned Managed Identity --------
//

// Storage Blob Data Owner (MI)
resource ra_storage_blob_mi 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(storageScopeId, managedIdentityPrincipalId, storageBlobDataOwnerRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageBlobDataOwnerRoleId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Storage Blob Data Owner role for Function App system-assigned managed identity'
  }
}

// Storage Queue Data Contributor (MI)
resource ra_storage_queue_mi 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(storageScopeId, managedIdentityPrincipalId, storageQueueDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageQueueDataContributorRoleId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Storage Queue Data Contributor role for Function App system-assigned managed identity'
  }
}

// Storage Table Data Contributor (MI)
resource ra_storage_table_mi 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(storageScopeId, managedIdentityPrincipalId, storageTableDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageTableDataContributorRoleId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Storage Table Data Contributor role for Function App system-assigned managed identity'
  }
}

//
// -------- Storage RBAC for User Identity (optional) --------
//

// Storage Blob Data Owner (User)
resource ra_storage_blob_user 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (allowUserIdentityPrincipal && !empty(userIdentityPrincipalId)) {
  name: guid(storageScopeId, userIdentityPrincipalId, storageBlobDataOwnerRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageBlobDataOwnerRoleId
    principalId: userIdentityPrincipalId
    principalType: 'User'
    description: 'Storage Blob Data Owner role for user identity (development/testing)'
  }
}

// Storage Queue Data Contributor (User)
resource ra_storage_queue_user 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (allowUserIdentityPrincipal && !empty(userIdentityPrincipalId)) {
  name: guid(storageScopeId, userIdentityPrincipalId, storageQueueDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageQueueDataContributorRoleId
    principalId: userIdentityPrincipalId
    principalType: 'User'
    description: 'Storage Queue Data Contributor role for user identity (development/testing)'
  }
}

// Storage Table Data Contributor (User)
resource ra_storage_table_user 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (allowUserIdentityPrincipal && !empty(userIdentityPrincipalId)) {
  name: guid(storageScopeId, userIdentityPrincipalId, storageTableDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageTableDataContributorRoleId
    principalId: userIdentityPrincipalId
    principalType: 'User'
    description: 'Storage Table Data Contributor role for user identity (development/testing)'
  }
}

//
// -------- Application Insights RBAC --------
//

// Monitoring Metrics Publisher (MI)
resource ra_appinsights_metrics_mi 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(managedIdentityPrincipalId)) {
  name: guid(appInsightsScopeId, managedIdentityPrincipalId, monitoringMetricsPublisherRoleId)
  scope: applicationInsights
  properties: {
    roleDefinitionId: monitoringMetricsPublisherRoleId
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Monitoring Metrics Publisher role for Function App system-assigned managed identity'
  }
}

// Monitoring Metrics Publisher (User)
resource ra_appinsights_metrics_user 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (allowUserIdentityPrincipal && !empty(userIdentityPrincipalId)) {
  name: guid(appInsightsScopeId, userIdentityPrincipalId, monitoringMetricsPublisherRoleId)
  scope: applicationInsights
  properties: {
    roleDefinitionId: monitoringMetricsPublisherRoleId
    principalId: userIdentityPrincipalId
    principalType: 'User'
    description: 'Monitoring Metrics Publisher role for user identity (development/testing)'
  }
}
