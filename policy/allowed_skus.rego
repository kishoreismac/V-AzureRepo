package main  # Changed from infra.allowed_skus

# Example mapping - customize per your org
allowed_skus = {
  "Microsoft.Web/sites": {"Y1": true, "P1V2": true, "S1": true},
  "Microsoft.Storage/storageAccounts": {"Standard_LRS": true, "Standard_GRS": true},
  "Microsoft.OperationalInsights/workspaces": {"PerGB2018": true, "Free": true, "Standalone": true},
  "Microsoft.Web/serverfarms": {"FC1": true}
}

# Deny resources that don't have a SKU policy defined
deny[msg] {
  resource := all_resources[_]  # Changed from data.main.all_resources[_]
  skus := allowed_skus[resource.type]
  not skus
  msg := sprintf("No SKU policy defined for %s - add to allowed_skus mapping", [resource.type])
}

deny[msg] {
  resource := all_resources[_]  # Changed from data.main.all_resources[_]
  resource.type == "Microsoft.Storage/storageAccounts"
  skus := allowed_skus[resource.type]
  sku := resource.sku.name
  not skus[sku]
  msg := sprintf("Resource %s has disallowed SKU %s", [resource.name, sku])
}

deny[msg] {
  resource := all_resources[_]  # Changed from data.main.all_resources[_]
  resource.type == "Microsoft.OperationalInsights/workspaces"
  skus := allowed_skus[resource.type]
  sku := resource.properties.sku.name
  not skus[sku]
  msg := sprintf("Log Analytics workspace %s has disallowed SKU %s", [resource.name, sku])
}

deny[msg] {
  resource := all_resources[_]  # Changed from data.main.all_resources[_]
  resource.type == "Microsoft.Web/serverfarms"
  skus := allowed_skus[resource.type]
  sku := resource.sku.name
  not skus[sku]
  msg := sprintf("App Service Plan %s has disallowed SKU %s", [resource.name, sku])
}