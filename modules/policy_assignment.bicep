// modules/policy_assignments.bicep
param environmentName string


// Policy definitions IDs (you can find more in Azure Portal or with CLI)
var policyDefinitions = {
  requireHttpsStorage: '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9'
  secureTransferStorage: '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9'
  managedIdentityFunction: '/providers/Microsoft.Authorization/policyDefinitions/f8a0fd5d-f5e4-4fc6-bdb5-8c0a1a5b0b7a'
  // Add more policy IDs as needed
}


// 1. POLICY: Storage accounts should only allow HTTPS traffic
resource httpsStoragePolicy 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'require-https-storage-${environmentName}'
  scope: resourceGroup()
  properties: {
    policyDefinitionId: policyDefinitions.requireHttpsStorage
    displayName: 'Require HTTPS for Storage - ${environmentName}'
    description: 'Enforces HTTPS-only traffic for storage accounts in ${environmentName} environment'
    enforcementMode: 'Default' // Can be 'Default' or 'DoNotEnforce'
    parameters: {
      effect: {
        value: 'Audit' // Can be 'Deny', 'Audit', or 'Disabled'
      }
    }
    nonComplianceMessages: [{
      message: 'Storage accounts must only allow HTTPS traffic for secure data transfer.'
    }]
  }
}

// 2. POLICY: Function Apps should use managed identity (optional)
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
output managedIdentityPolicyAssignmentId string = managedIdentityPolicy.id
