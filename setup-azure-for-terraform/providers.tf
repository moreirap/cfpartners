terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.78.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45.0"
    }
    github = {
      source = "integrations/github"
      version = "~> 4.19.0" // latest 5.40.0
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}
provider "github" {
  token = var.github_token
}