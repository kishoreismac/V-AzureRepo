package main

# Import all policies - use correct package names
import data.infra.allowed_skus
# If your file is disallow_public_blob_access.rego, the package should be infra.disallow_public_blob_access
import data.infra.disallow_public_blob_access
# If your file is enforce_private_endpoints.rego, the package should be infra.enforce_private_endpoints
import data.infra.enforce_private_endpoints
import data.infra.ensure_tags
import data.infra.no_public_ip
import data.infra.require_diagnostic_settings
import data.infra.require_https

# Collect all resources from nested deployments
all_resources[resource] {
    deployment := input.resources[_]
    deployment.type == "Microsoft.Resources/deployments"
    resource := deployment.properties.template.resources[_]
}

# Forward deny rules - FIXED: use 'some' to avoid unsafe variable errors
deny[msg] {
    some i
    msg := infra.allowed_skus.deny[i]
}

deny[msg] {
    some i
    msg := infra.disallow_public_blob_access.deny[i]
}

deny[msg] {
    some i
    msg := infra.enforce_private_endpoints.deny[i]
}

deny[msg] {
    some i
    msg := infra.ensure_tags.deny[i]
}

deny[msg] {
    some i
    msg := infra.no_public_ip.deny[i]
}

deny[msg] {
    some i
    msg := infra.require_diagnostic_settings.deny[i]
}

deny[msg] {
    some i
    msg := infra.require_https.deny[i]
}

# Debug rule to test
deny["Test: Policy evaluation is working"] {
    true
}