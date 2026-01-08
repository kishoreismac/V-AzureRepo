package azure.skus

# Define allowed SKUs for different resource types
allowed_storage_skus := ["Standard_LRS", "Standard_GRS", "Standard_ZRS"]
allowed_function_skus := ["Y1", "FC1", "EP1", "EP2", "EP3"]
allowed_sql_skus := ["Basic", "S0", "S1", "S2"]

# Deny storage accounts with disallowed SKUs
deny[msg] {
    resource := input.resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    sku := resource.properties.sku.name
    not sku_allowed(sku, allowed_storage_skus)
    msg := sprintf("Storage account '%s' uses disallowed SKU: %s. Allowed: %v", [resource.name, sku, allowed_storage_skus])
}

# Deny App Service Plans with disallowed SKUs
deny[msg] {
    resource := input.resources[_]
    resource.type == "Microsoft.Web/serverfarms"
    sku := resource.sku.name
    not sku_allowed(sku, allowed_function_skus)
    msg := sprintf("App Service Plan '%s' uses disallowed SKU: %s. Allowed: %v", [resource.name, sku, allowed_function_skus])
}

# Helper function to check if SKU is allowed
sku_allowed(sku, allowed_list) {
    sku == allowed_list[_]
}
