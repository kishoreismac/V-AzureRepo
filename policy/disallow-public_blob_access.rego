package azure.storage

# Deny storage accounts with public blob access enabled
deny[msg] {
    resource := input.resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    public_blob_access_enabled(resource)
    msg := sprintf("Storage account '%s' must not allow public blob access. Set allowBlobPublicAccess to false", [resource.name])
}

# Deny blob containers with public access
deny[msg] {
    resource := input.resources[_]
    resource.type == "Microsoft.Storage/storageAccounts/blobServices/containers"
    container_has_public_access(resource)
    msg := sprintf("Blob container '%s' must not have public access. Use private access only", [resource.name])
}

# Deny storage accounts without minimum TLS version
deny[msg] {
    resource := input.resources[_]
    resource.type == "Microsoft.Storage/storageAccounts"
    not has_minimum_tls(resource)
    msg := sprintf("Storage account '%s' must enforce minimum TLS version 1.2", [resource.name])
}

# Check if storage account allows public blob access
public_blob_access_enabled(resource) {
    resource.properties.allowBlobPublicAccess == true
}

public_blob_access_enabled(resource) {
    not resource.properties.allowBlobPublicAccess
    # Default is true if not specified, so deny if not explicitly set to false
}

# Check if blob container has public access
container_has_public_access(resource) {
    access_level := resource.properties.publicAccess
    access_level != "None"
}

# Check minimum TLS version
has_minimum_tls(resource) {
    tls := resource.properties.minimumTlsVersion
    tls == "TLS1_2"
}

has_minimum_tls(resource) {
    tls := resource.properties.minimumTlsVersion
    tls == "TLS1_3"
}
