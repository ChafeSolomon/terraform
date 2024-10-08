# Configure Terraform
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.0.1"
    }
    random = {
      source = "hashicorp/random"
      version = "3.6.2"
    }
  }
  backend "azurerm" {
    resource_group_name  = "AZ104"
    storage_account_name = "az104tfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# Configure the Azure Resource Manager Provider
provider "azurerm" {
  features {}
}

# Configure the Azure Active Directory Provider
provider "azuread" {}

provider "random" {
}

