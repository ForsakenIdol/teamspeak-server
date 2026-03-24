data "azurerm_resource_group" "cicd" {
  name = "cicd"
}

# Reference: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/ssh_public_key
data "azurerm_ssh_public_key" "teamspeak_ssh" {
  name                = "teamspeak-ssh"
  resource_group_name = data.azurerm_resource_group.cicd.name
}
