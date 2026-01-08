package main

# Import all policies
import data.infra.allowed_skus
import data.infra.disallow_public_blob_access
import data.infra.ensure_private_endpoints
import data.infra.ensure_tags
import data.infra.no-public_ip
import data.infra.require_diagnostic_settings
import data.infra.require_https

# Collect all resources from nested deployments
all_resources[resource] {
    deployment := input.resources[_]
    deployment.type == "Microsoft.Resources/deployments"
    resource := deployment.properties.template.resources[_]
}

# Forward deny rules using the collected resources
deny[msg] {
    msg := infra.allowed_skus.deny[_]
}

deny[msg] {
    msg := infra.disallow_public_blob_access.deny[_]
}

deny[msg] {
    msg := infra.enforce_private_endpoints.deny[_]
}

deny[msg] {
    msg := infra.ensure_tags.deny[_]
}

deny[msg] {
    msg := infra.no_public_ip.deny[_]
}

deny[msg] {
    msg := infra.require_diagnostic_settings.deny[_]
}

deny[msg] {
    msg := infra.require_https.deny[_]
}