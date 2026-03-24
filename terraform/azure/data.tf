data "azurerm_resource_group" "cicd" {
    name = "cicd"
}

data "azurerm_ssh_public_key" "teamspeak_ssh" {
    name                = "teamspeak-ssh"
    resource_group_name = data.azurerm_resource_group.cicd.name
}
