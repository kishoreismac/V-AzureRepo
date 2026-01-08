package main

# Example: require storage accounts to restrict public access via networkAcls
deny[msg] {
  resource := all_resources[_]
  resource.type == "Microsoft.Storage/storageAccounts"
  not resource.properties.networkAcls
  msg := sprintf("Storage %s missing networkAcls/private endpoints", [resource.name])
}

deny[msg] {
  resource := all_resources[_]
  resource.type == "Microsoft.Storage/storageAccounts"
  resource.properties.networkAcls.defaultAction == "Allow"
  msg := sprintf("Storage %s allows public access (defaultAction=Allow)", [resource.name])
}
