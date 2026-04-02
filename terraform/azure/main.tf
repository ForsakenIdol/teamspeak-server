resource "azurerm_resource_group" "teamspeak" {
  name     = "teamspeak"
  location = "australiaeast"
}

# Network

resource "azurerm_virtual_network" "teamspeak_vpc" {
  name                = "teamspeak-vpc"
  location            = azurerm_resource_group.teamspeak.location
  resource_group_name = azurerm_resource_group.teamspeak.name
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "teamspeak_public_subnet_1" {
  name                            = "teamspeak-public-subnet-1"
  resource_group_name             = azurerm_resource_group.teamspeak.name
  virtual_network_name            = azurerm_virtual_network.teamspeak_vpc.name
  address_prefixes                = ["10.1.0.0/16"]
  default_outbound_access_enabled = true
}

# IP and NIC

# Provisions a static IP, similar to an AWS EIP
resource "azurerm_public_ip" "eip" {
  name                = "teamspeak-eip"
  location            = azurerm_resource_group.teamspeak.location
  resource_group_name = azurerm_resource_group.teamspeak.name
  allocation_method   = "Static"
  ip_version          = "IPv4"
  sku_tier            = "Regional"

  lifecycle {
    create_before_destroy = true
  }
}

# Network interface for the VM
resource "azurerm_network_interface" "eni" {
  name                = "teamspeak-eni"
  location            = azurerm_resource_group.teamspeak.location
  resource_group_name = azurerm_resource_group.teamspeak.name

  ip_configuration {
    name                          = "primary-ip_config"
    public_ip_address_id          = azurerm_public_ip.eip.id
    subnet_id                     = azurerm_subnet.teamspeak_public_subnet_1.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }
}

# Network Security Group

resource "azurerm_network_security_group" "nsg" {
  name                = "teamspeak-nsg"
  location            = azurerm_resource_group.teamspeak.location
  resource_group_name = azurerm_resource_group.teamspeak.name

  # General Rules

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Teamspeak-Specific Rules

  security_rule {
    name                       = "teamspeak-voice-udp"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "9987"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "teamspeak-file-transfer"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30033"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "teamspeak-web-query"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "associate_nsg_to_eni" {
  network_interface_id      = azurerm_network_interface.eni.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Compute

resource "azurerm_linux_virtual_machine" "teamspeak_vm" {
  name                            = "teamspeak-server"
  location                        = azurerm_resource_group.teamspeak.location
  resource_group_name             = azurerm_resource_group.teamspeak.name
  network_interface_ids           = [azurerm_network_interface.eni.id]
  size                            = "Standard_B2ats_v2"
  disable_password_authentication = true

  /*
    az vm image list \
        --location australiaeast \
        --publisher Canonical \
        --offer ubuntu-24_04-lts \
        --sku server \
        --architecture x64 \
        --query "[?imageDeprecationStatus.imageState != 'ScheduledForDeprecation']" \
        --all \
        --output table
    */
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = "ubuntu"
  admin_ssh_key {
    username   = "ubuntu"
    public_key = data.azurerm_ssh_public_key.teamspeak_ssh.public_key
  }

  user_data = filebase64("${path.module}/utils/user-data.yaml")
}

# Storage

resource "azurerm_managed_disk" "teamspeak_disk" {
  name                 = "teamspeak-data-disk"
  location             = azurerm_resource_group.teamspeak.location
  resource_group_name  = azurerm_resource_group.teamspeak.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach_disk_to_vm" {
  virtual_machine_id = azurerm_linux_virtual_machine.teamspeak_vm.id
  managed_disk_id    = azurerm_managed_disk.teamspeak_disk.id
  lun                = 10
  caching            = "ReadWrite"
}
