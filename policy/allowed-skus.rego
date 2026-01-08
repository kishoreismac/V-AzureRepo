package infra.allowed_skus

# Example mapping - customize per your org
allowed_skus = {
  "Microsoft.Web/sites": ["Y1","P1V2","S1"],
  "Microsoft.Storage/storageAccounts": ["Standard_LRS","Standard_GRS"]
}

deny[msg] {
  resource := input.resources[_]
  skus := allowed_skus[resource.type]
  not skus
  msg := sprintf("No SKU policy defined for %s", [resource.type])
}

deny[msg] {
  resource := input.resources[_]
  skus := allowed_skus[resource.type]
  sku := resource.sku.name
  not sku in skus
  msg := sprintf("Resource %s has disallowed SKU %s", [resource.name, sku])
}
