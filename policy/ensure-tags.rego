package azure.tags

# Deny resources without required tags
deny[msg] {
    resource := input.resources[_]
    not resource.tags
    msg := sprintf("Resource '%s' is missing tags", [resource.name])
}

deny[msg] {
    resource := input.resources[_]
    resource.tags
    required_tags := ["environment", "owner", "project"]
    missing_tag := required_tags[_]
    not resource.tags[missing_tag]
    msg := sprintf("Resource '%s' is missing required tag: %s", [resource.name, missing_tag])
}

# Validate tag values are not empty
deny[msg] {
    resource := input.resources[_]
    resource.tags
    tag_key := [key | resource.tags[key]][_]
    tag_value := resource.tags[tag_key]
    tag_value == ""
    msg := sprintf("Resource '%s' has empty value for tag: %s", [resource.name, tag_key])
}
