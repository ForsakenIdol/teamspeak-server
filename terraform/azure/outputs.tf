output "vm_public_ip" {
  value = azurerm_public_ip.eip.ip_address
}

