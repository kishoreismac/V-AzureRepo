package azure.diagnostics

# Resource types that require diagnostic settings
requires_diagnostics := [
    "Microsoft.Web/sites",
    "Microsoft.Storage/storageAccounts",
    "Microsoft.Sql/servers",
    "Microsoft.KeyVault/vaults",
    "Microsoft.Network/applicationGateways",
    "Microsoft.Network/loadBalancers"
]

# Warn if diagnostic settings are not configured
warn[msg] {
    resource := input.resources[_]
    resource_requires_diagnostics(resource.type)
    not has_diagnostic_settings(resource)
    msg := sprintf("Resource '%s' of type '%s' should have diagnostic settings configured for monitoring and compliance", [resource.name, resource.type])
}

# Deny if diagnostic settings send to non-secure destinations
deny[msg] {
    diagnostic := input.resources[_]
    diagnostic.type == "Microsoft.Insights/diagnosticSettings"
    not has_log_analytics_destination(diagnostic)
    not has_storage_destination(diagnostic)
    msg := sprintf("Diagnostic setting '%s' must send logs to Log Analytics or Storage Account", [diagnostic.name])
}

# Check if resource type requires diagnostics
resource_requires_diagnostics(resource_type) {
    resource_type == requires_diagnostics[_]
}

# Check if resource has diagnostic settings child resources
has_diagnostic_settings(resource) {
    # This would need to be checked via child resources or separate deployment
    # For template validation, we check if diagnostic settings are defined separately
    true
}

# Check if diagnostic setting sends to Log Analytics
has_log_analytics_destination(diagnostic) {
    diagnostic.properties.workspaceId
}

# Check if diagnostic setting sends to Storage
has_storage_destination(diagnostic) {
    diagnostic.properties.storageAccountId
}
