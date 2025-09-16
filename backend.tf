terraform {
  required_version = ">= 1.5.0"
  backend "azurerm" {
    resource_group_name   = "tfstate-rg"
    storage_account_name  = "<your-storage-account-name>"
    container_name        = "tfstate"
    key                   = "wordpress.tfstate"
  }
}
