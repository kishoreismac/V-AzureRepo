package infra.ensure_tags

deny[msg] {
  resource := data.main.all_resources[_]
  # Skip resource types that might not support tags
  resource.type != "Microsoft.Storage/storageAccounts/blobServices"
  resource.type != "Microsoft.Storage/storageAccounts/blobServices/containers"
  resource.type != "Microsoft.Storage/storageAccounts/queueServices"
  resource.type != "Microsoft.Storage/storageAccounts/tableServices"
  not resource.tags
  msg := sprintf("Resource %s of type %s is missing tags", [resource.name, resource.type])
}

deny[msg] {
  resource := data.main.all_resources[_]
  resource.tags
  not resource.tags["environment"]
  msg := sprintf("Resource %s does not have an 'environment' tag", [resource.name])
}

deny[msg] {
  resource := data.main.all_resources[_]
  resource.tags
  not resource.tags["owner"]
  msg := sprintf("Resource %s does not have an 'owner' tag", [resource.name])
}