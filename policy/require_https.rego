package main

deny[msg] {
  resource := all_resources[_]
  resource.type == "Microsoft.Web/sites"
  not resource.properties.siteConfig.http20Enabled
  msg := sprintf("Web App %s does not have HTTP/2 enabled (check siteConfig.http20Enabled)", [resource.name])
}
