package infra.require_diagnostic_settings

# Ensure diagnostic settings or log_analytics workspace forwarding exists on resources
deny[msg] {
  resource := input.resources[_]
  resource.type == "Microsoft.Web/sites"
  not resource.properties.siteConfig
  msg := sprintf("Web App %s missing siteConfig (unable to verify diagnostic settings)", [resource.name])
}
