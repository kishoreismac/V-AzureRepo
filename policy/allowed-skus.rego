package infra.allowed_skus

# define allowed SKUs for example resource types
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
  sku := resource.sku.name
  skus := allowed_skus[resource.type]
  not sku in skus
  msg := sprintf("Resource %s has disallowed SKU %s", [resource.name, sku])
}
