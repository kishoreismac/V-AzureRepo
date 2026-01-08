package azure.https

# Deny storage accounts without HTTPS-only requirement
deny[msg] {
    resource := input.resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    not https_only_enabled(resource)
    msg := sprintf("Storage account '%s' must enable supportsHttpsTrafficOnly", [resource.name])
}

# Deny web apps without HTTPS-only requirement
deny[msg] {
    resource := input.resources[_]
    is_web_resource(resource.type)
    not web_https_only_enabled(resource)
    msg := sprintf("Web resource '%s' must enable httpsOnly setting", [resource.name])
}

# Deny App Service with TLS version < 1.2
deny[msg] {
    resource := input.resources[_]
    is_web_resource(resource.type)
    tls_version := resource.properties.siteConfig.minTlsVersion
    tls_version != "1.2"
    tls_version != "1.3"
    msg := sprintf("Web resource '%s' must use TLS 1.2 or higher. Current: %s", [resource.name, tls_version])
}

# Check if storage account has HTTPS only enabled
https_only_enabled(resource) {
    resource.properties.supportsHttpsTrafficOnly == true
}

# Check if web resource has HTTPS only enabled
web_https_only_enabled(resource) {
    resource.properties.httpsOnly == true
}

# Identify web resources
is_web_resource(resource_type) {
    web_types := [
        "Microsoft.Web/sites",
        "Microsoft.Web/sites/slots"
    ]
    resource_type == web_types[_]
}
