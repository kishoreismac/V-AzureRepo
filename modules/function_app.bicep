@description('Location for the Function App')
param location string

@description('Function App name')
param functionAppName string

@description('App Service Plan resourceId (Flex Consumption FC1)')
param serverFarmResourceId string

@description('Storage account name (used to build service URIs)')
param storageAccountName string

@description('Blob container URI used for Flex deployment package. Example: https://<account>.blob.core.windows.net/<container>')
param deploymentBlobContainerUri string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Tags to apply')
param tags object = {}

@allowed(['dotnet-isolated','python','java','node','powerShell'])
param functionAppRuntime string = 'python'

@allowed(['3.10','3.11','3.12','7.4','8.0','9.0','10','11','17','20','21','22'])
param functionAppRuntimeVersion string = '3.11'

@minValue(40)
@maxValue(1000)
param maximumInstanceCount int = 100

@allowed([512,2048,4096])
param instanceMemoryMB int = 2048

// Flex requires functionAppConfig on CREATE.
// Flex also rejects siteConfig.linuxFxVersion, so do NOT set it.

var functionAppConfigPayload = {
  deployment: {
    storage: {
      type: 'blobContainer'
      value: deploymentBlobContainerUri
      authentication: {
        type: 'SystemAssignedIdentity'
      }
    }
  }
  scaleAndConcurrency: {
    maximumInstanceCount: maximumInstanceCount
    instanceMemoryMB: instanceMemoryMB
  }
  runtime: {
    name: functionAppRuntime
    version: functionAppRuntimeVersion
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }

  // Use union()+json() to bypass any Bicep type-definition gaps around functionAppConfig.
  properties: union({
    serverFarmId: serverFarmResourceId
    httpsOnly: true

    // DO NOT include linuxFxVersion for Flex
    siteConfig: {
      alwaysOn: false
      appSettings: [
        // Storage using Managed Identity (no keys)
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__blobServiceUri'
          value: 'https://${storageAccountName}.blob.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__queueServiceUri'
          value: 'https://${storageAccountName}.queue.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__tableServiceUri'
          value: 'https://${storageAccountName}.table.${environment().suffixes.storage}'
        }

        // App Insights
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APPLICATIONINSIGHTS_AUTHENTICATION_STRING'
          value: 'Authorization=AAD'
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }

        // Common package behavior
        // {
        //   name: 'WEBSITE_RUN_FROM_PACKAGE'
        //   value: '1'
        // }
      ]
    }
  }, json('{ "functionAppConfig": {} }'), {
    functionAppConfig: functionAppConfigPayload
  })
}

output name string = functionApp.name
output resourceId string = functionApp.id
output principalId string = functionApp.identity.principalId
