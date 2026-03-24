resource "azurerm_resource_group" "teamspeak" {
  name     = "teamspeak"
  location = "australiaeast"
}

# Network

resource "azurerm_virtual_network" "teamspeak_vpc" {
    name = "teamspeak-vpc"
    location = azurerm_resource_group.teamspeak.location
    resource_group_name = azurerm_resource_group.teamspeak.name
    address_space = [ "10.0.0.0/8" ]
}

resource "azurerm_subnet" "teamspeak_public_subnet_1" {
    name = "teamspeak-public-subnet-1"
    resource_group_name = azurerm_resource_group.teamspeak.name
    virtual_network_name = azurerm_virtual_network.teamspeak_vpc.name
    address_prefixes = [ "10.1.0.0/16" ]
    default_outbound_access_enabled = true
}

# IP and NIC

# Provisions a static IP, similar to an AWS EIP
resource "azurerm_public_ip" "eip" {
    name = "teamspeak-eip"
    location = azurerm_resource_group.teamspeak.location
    resource_group_name = azurerm_resource_group.teamspeak.name
    allocation_method = "Static"
    ip_version = "IPv4"
    sku_tier = "Regional"
}

# Network interface for the VM
resource "azurerm_network_interface" "eni" {
    name                = "teamspeak-eni"
    location            = azurerm_resource_group.teamspeak.location
    resource_group_name = azurerm_resource_group.teamspeak.name

    ip_configuration {
        name = "primary-ip_config"
        public_ip_address_id = azurerm_public_ip.eip.id
        subnet_id = azurerm_subnet.teamspeak_public_subnet_1.id
        primary = true
    }
}

# (add NSG later for the ENI, with the current config all ports are open)

# Compute