package main

# Import all policies
import data.infra.allowed-skus
import data.infra.disallow-public_blob_access
import data.infra.ensure-private-endpoints
import data.infra.ensure-tags
import data.infra.no-public-ip
import data.infra.require-diagnostic-settings
import data.infra.require-https

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
    msg := infra.disallow-public_blob_access.deny[_]
}

deny[msg] {
    msg := infra.require_private_endpoints.deny[_]
}

deny[msg] {
    msg := infra.ensure-tags.deny[_]
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