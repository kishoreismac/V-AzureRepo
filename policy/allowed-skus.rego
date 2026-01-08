package infra.allowed_skus

# Example mapping - customize per your org
# Add resource types as needed. Resources without SKU policies defined will trigger a policy failure.
# This is intentional to ensure all resource types are explicitly reviewed and approved.
allowed_skus = {
  "Microsoft.Web/sites": {"Y1": true, "P1V2": true, "S1": true},
  "Microsoft.Storage/storageAccounts": {"Standard_LRS": true, "Standard_GRS": true}
}

# Deny resources that don't have a SKU policy defined
# This ensures explicit approval of all resource types
deny[msg] {
  resource := input.resources[_]
  skus := allowed_skus[resource.type]
  not skus
  msg := sprintf("No SKU policy defined for %s - add to allowed_skus mapping", [resource.type])
}

deny[msg] {
  resource := input.resources[_]
  skus := allowed_skus[resource.type]
  sku := resource.sku.name
  not skus[sku]
  msg := sprintf("Resource %s has disallowed SKU %s", [resource.name, sku])
}