terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.65.0"
    }
  }

  cloud {
    organization = "forsakenidol-organization-1"
    workspaces {
      name = "teamspeak-server"
    }
  }
}

provider "azurerm" {
  # "Visual Studio Professional Subscription" in my personal tenant
  subscription_id                 = "4768df7b-f6ff-4b8b-9b0a-3c03595c7ef2"
  resource_provider_registrations = "none"
  features {}
}
