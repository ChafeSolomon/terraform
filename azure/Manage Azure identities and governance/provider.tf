# Configure Terraform
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.0.1"
    }
  }
  backend "azurerm" {
    resource_group_name  = "AZ104"
    storage_account_name = "az104tfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc = true
}
}

# Configure the Azure Resource Manager Provider
provider "azurerm" {
  use_oidc = true
  features {}
}

# Configure the Azure Active Directory Provider
provider "azuread"{}

# Create project RG
resource "azurerm_resource_group" "az104_rg" {
  name     = "AZ104"
  location = "eastus"
}
