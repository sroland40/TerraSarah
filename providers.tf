terraform {
  required_version = ">=1.0"


  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }

    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = "true"
}

