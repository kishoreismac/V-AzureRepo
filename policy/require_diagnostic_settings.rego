package main

# Ensure diagnostic settings or log_analytics workspace forwarding exists on resources
deny[msg] {
  resource := all_resources[_]
  resource.type == "Microsoft.Web/sites"
  not resource.properties.siteConfig
  msg := sprintf("Web App %s missing siteConfig (unable to verify diagnostic settings)", [resource.name])
}
