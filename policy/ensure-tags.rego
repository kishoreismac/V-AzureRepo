package infra.require_tags

deny[msg] {
  resource := input.resources[_]
  not resource.tags
  msg := sprintf("Resource %s of type %s is missing tags", [resource.name, resource.type])
}

deny[msg] {
  resource := input.resources[_]
  resource.tags
  not resource.tags["azd-env-name"]
  msg := sprintf("Resource %s does not have an 'azd-env-name' tag", [resource.name])
}
