package infra.allowed_skus

# define allowed SKUs for example resource types
allowed_skus = {
  "Microsoft.Web/sites": ["Y1","P1V2","S1"],
  "Microsoft.Storage/storageAccounts": ["Standard_LRS","Standard_GRS"]
}

# Only check resources that have SKU policies defined
deny[msg] {
  resource := input.resources[_]
  allowed_skus[resource.type]
  sku := resource.sku.name
  skus := allowed_skus[resource.type]
  not sku in skus
  msg := sprintf("Resource %s has disallowed SKU %s (allowed: %v)", [resource.name, sku, skus])
}
