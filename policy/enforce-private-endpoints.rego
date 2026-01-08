package azure.privateendpoints

# Resources that should have private endpoints
requires_private_endpoint := [
    "Microsoft.Storage/storageAccounts",
    "Microsoft.Sql/servers",
    "Microsoft.KeyVault/vaults",
    "Microsoft.DBforPostgreSQL/servers",
    "Microsoft.DBforMySQL/servers"
]

# Deny resources without private endpoint configuration
deny[msg] {
    resource := input.resources[_]
    resource_requires_pe(resource.type)
    not has_private_endpoint_configured(resource)
    msg := sprintf("Resource '%s' of type '%s' must have private endpoint configured", [resource.name, resource.type])
}

# Deny storage accounts with public network access enabled
deny[msg] {
    resource := input.resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    resource.properties.publicNetworkAccess == "Enabled"
    msg := sprintf("Storage account '%s' has public network access enabled. Use private endpoints only.", [resource.name])
}

# Check if resource type requires private endpoint
resource_requires_pe(resource_type) {
    resource_type == requires_private_endpoint[_]
}

# Check if resource has private endpoint configuration
has_private_endpoint_configured(resource) {
    resource.properties.privateEndpointConnections
    count(resource.properties.privateEndpointConnections) > 0
}

has_private_endpoint_configured(resource) {
    resource.properties.publicNetworkAccess == "Disabled"
}
