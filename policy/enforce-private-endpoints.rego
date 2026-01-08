package infra.require_private_endpoints

# Example: require storage accounts to have networkAcls with defaultAction = Deny (i.e., restrict public access)
deny[msg] {
  resource := input.resources[_]
  resource.type == "Microsoft.Storage/storageAccounts"
  not resource.properties.networkAcls
  msg := sprintf("Storage %s missing networkAcls/private endpoints", [resource.name])
}

deny[msg] {
  resource := input.resources[_]
  resource.type == "Microsoft.Storage/storageAccounts"
  resource.properties.networkAcls.defaultAction == "Allow"
  msg := sprintf("Storage %s allows public access (defaultAction=Allow)", [resource.name])
}
