package infra.disallow-public_blob_access

deny[msg] {
  resource := data.main.all_resources[_]
  resource.type == "Microsoft.Storage/storageAccounts"
  properties := resource.properties
  properties.allowBlobPublicAccess == true
  msg := sprintf("Storage %s allows public blob access (allowBlobPublicAccess=true)", [resource.name])
}
