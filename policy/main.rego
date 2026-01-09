package main

# ========================================
# Extract all resources from ARM template
# ========================================

# Collect resources from top-level
all_resources[resource] {
    resource := input.resources[_]
}

# Collect resources from nested deployments
all_resources[resource] {
    deployment := input.resources[_]
    deployment.type == "Microsoft.Resources/deployments"
    resource := deployment.properties.template.resources[_]
}

# ========================================
# POLICY 1: Allowed SKUs
# ========================================

allowed_skus := {
    "Microsoft.Web/sites": {"Y1": true, "P1V2": true, "S1": true, "B1": true, "B2": true},
    "Microsoft.Storage/storageAccounts": {"Standard_LRS": true, "Standard_GRS": true, "Standard_ZRS": true},
    "Microsoft.OperationalInsights/workspaces": {"PerGB2018": true, "Free": true, "Standalone": true},
    "Microsoft.Web/serverfarms": {"FC1": true, "Y1": true, "B1": true, "P1V2": true, "S1": true}
}

deny[msg] {
    resource := all_resources[_]
    resource.sku
    skus := allowed_skus[resource.type]
    skus  # SKU policy exists for this type
    sku_name := resource.sku.name
    not skus[sku_name]
    msg := sprintf("❌ Resource '%s' has disallowed SKU '%s' (type: %s)", [resource.name, sku_name, resource.type])
}

# ========================================
# POLICY 2: No Public Blob Access
# ========================================

deny[msg] {
    resource := all_resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    properties := resource.properties
    properties.allowBlobPublicAccess == true
    msg := sprintf("❌ Storage '%s' allows public blob access (set allowBlobPublicAccess=false)", [resource.name])
}

# ========================================
# POLICY 3: Network ACLs Required
# ========================================

deny[msg] {
    resource := all_resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    not resource.properties.networkAcls
    msg := sprintf("❌ Storage '%s' missing networkAcls configuration", [resource.name])
}

deny[msg] {
    resource := all_resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    resource.properties.networkAcls
    resource.properties.networkAcls.defaultAction == "Allow"
    msg := sprintf("⚠️  Storage '%s' allows public network access (set networkAcls.defaultAction=Deny for production)", [resource.name])
}

# ========================================
# POLICY 4: Required Tags
# ========================================

required_tags := ["environment", "owner"]

deny[msg] {
    resource := all_resources[_]
    
    # Skip child resources that don't support tags
    not contains(resource.type, "/blobServices")
    not contains(resource.type, "/queueServices")
    not contains(resource.type, "/tableServices")
    not contains(resource.type, "/fileServices")
    not contains(resource.type, "/containers")
    
    not resource.tags
    msg := sprintf("❌ Resource '%s' (type: %s) is missing tags", [resource.name, resource.type])
}

deny[msg] {
    resource := all_resources[_]
    resource.tags
    
    # Check each required tag
    tag := required_tags[_]
    not resource.tags[tag]
    
    msg := sprintf("❌ Resource '%s' missing required tag: '%s'", [resource.name, tag])
}

# ========================================
# POLICY 5: HTTPS Only
# ========================================

deny[msg] {
    resource := all_resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    properties := resource.properties
    not properties.supportsHttpsTrafficOnly
    msg := sprintf("❌ Storage '%s' does not enforce HTTPS only (set supportsHttpsTrafficOnly=true)", [resource.name])
}

deny[msg] {
    resource := all_resources[_]
    resource.type == "Microsoft.Web/sites"
    properties := resource.properties
    not properties.httpsOnly
    msg := sprintf("❌ Web App '%s' does not enforce HTTPS only (set httpsOnly=true)", [resource.name])
}

# ========================================
# POLICY 6: Minimum TLS Version
# ========================================

deny[msg] {
    resource := all_resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    properties := resource.properties
    tls := properties.minimumTlsVersion
    tls != "TLS1_2"
    msg := sprintf("❌ Storage '%s' not using TLS 1.2 minimum (currently: %s)", [resource.name, tls])
}

deny[msg] {
    resource := all_resources[_]
    resource.type == "Microsoft.Web/sites"
    properties := resource.properties
    site_config := properties.siteConfig
    site_config  # Only check if siteConfig exists
    tls := site_config.minTlsVersion
    not tls
    msg := sprintf("❌ Web App '%s' missing minTlsVersion in siteConfig", [resource.name])
}

deny[msg] {
    resource := all_resources[_]
    resource.type == "Microsoft.Web/sites"
    properties := resource.properties
    site_config := properties.siteConfig
    tls := site_config.minTlsVersion
    tls != "1.2"
    tls != "1.3"
    msg := sprintf("❌ Web App '%s' not using TLS 1.2+ (currently: %s)", [resource.name, tls])
}

# ========================================
# POLICY 7: No Public IPs (Optional - can be disabled)
# ========================================

# Uncomment to enforce no public IPs
# deny[msg] {
#     resource := all_resources[_]
#     resource.type == "Microsoft.Network/publicIPAddresses"
#     msg := sprintf("❌ Public IP '%s' is not allowed in this environment", [resource.name])
# }

# ========================================
# Success message if no violations
# ========================================

pass[msg] {
    count(deny) == 0
    msg := "✅ All policy checks passed!"
}