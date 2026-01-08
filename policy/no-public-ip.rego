package infra.no_public_ip

deny[msg] {
  resource := data.main.all_resources[_]
  resource.type == "Microsoft.Network/publicIPAddresses"
  msg := sprintf("Public IP %s is not allowed", [resource.name])
}
