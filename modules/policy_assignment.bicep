// modules/policy_assignments.bicep
param environmentName string

// CORRECTED Policy definitions IDs
var policyDefinitions = {
  // Storage HTTPS: "Secure transfer to storage accounts should be enabled"
  requireHttpsStorage: '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9'
  
  // Function App managed identity: "Function apps should use managed identity"
  managedIdentityFunction: '/providers/Microsoft.Authorization/policyDefinitions/0da106f2-4ca3-48e8-bc85-c638fe6aea8f'
  
  // Alternative: "Managed identity should be used in your Function app"
  // managedIdentityFunctionAlt: '/providers/Microsoft.Authorization/policyDefinitions/0da106f2-4ca3-48e8-bc85-c638fe6aea8f'
}

// 1. POLICY: Storage accounts should only allow HTTPS traffic
resource httpsStoragePolicy 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'require-https-storage-${environmentName}'
  scope: resourceGroup()
  properties: {
    policyDefinitionId: policyDefinitions.requireHttpsStorage
    displayName: 'Require HTTPS for Storage - ${environmentName}'
    description: 'Enforces HTTPS-only traffic for storage accounts in ${environmentName} environment'
    enforcementMode: 'Default'
    parameters: {
      effect: {
        value: 'Audit'
      }
    }
    nonComplianceMessages: [{
      message: 'Storage accounts must only allow HTTPS traffic for secure data transfer.'
    }]
  }
}

// 2. POLICY: Function Apps should use managed identity
resource managedIdentityPolicy 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'require-managed-identity-func-${environmentName}'
  scope: resourceGroup()
  properties: {
    policyDefinitionId: policyDefinitions.managedIdentityFunction
    displayName: 'Require Managed Identity for Functions - ${environmentName}'
    description: 'Enforces managed identity usage for Function Apps in ${environmentName}'
    enforcementMode: 'Default'
    parameters: {
      effect: {
        value: 'Audit'
      }
    }
  }
}

// Outputs
output httpsPolicyAssignmentId string = httpsStoragePolicy.id
output httpsPolicyAssignmentName string = httpsStoragePolicy.name
