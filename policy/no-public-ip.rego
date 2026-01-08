package azure.network

# Deny creation of public IP addresses
deny[msg] {
    resource := input.resources[_]
    resource.type == "Microsoft.Network/publicIPAddresses"
    msg := sprintf("Public IP address '%s' is not allowed. Use private networking instead.", [resource.name])
}

# Deny VMs with public IP configurations
deny[msg] {
    resource := input.resources[_]
    resource.type == "Microsoft.Compute/virtualMachines"
    nic := resource.properties.networkProfile.networkInterfaces[_]
    has_public_ip(nic)
    msg := sprintf("Virtual Machine '%s' has a public IP address. Use private networking or bastion host.", [resource.name])
}

# Check if network interface has public IP
has_public_ip(nic) {
    nic.properties.ipConfigurations[_].properties.publicIPAddress
}
