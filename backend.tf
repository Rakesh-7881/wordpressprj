terraform {
  backend "azurerm" {
    resource_group_name   = "tfstate-rg"
    storage_account_name  = "tfstate69c67a8b"
    container_name        = "tfstate"
    key                   = "wordpress.tfstate"
  }
}
