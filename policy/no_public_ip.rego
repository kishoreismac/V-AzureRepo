package main

deny[msg] {
  resource := all_resources[_]
  resource.type == "Microsoft.Network/publicIPAddresses"
  msg := sprintf("Public IP %s is not allowed", [resource.name])
}
