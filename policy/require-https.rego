package infra.require_https

deny[msg] {
  resource := data.main.all_resources[_]
  resource.type == "Microsoft.Web/sites"
  not resource.properties.siteConfig.http20Enabled
  msg := sprintf("Web App %s does not have HTTP/2 enabled (check siteConfig.http20Enabled)", [resource.name])
}
