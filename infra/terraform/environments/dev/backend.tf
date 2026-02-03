terraform {
  backend "azurerm" {
    resource_group_name  = "fdic-dev-rg"
    storage_account_name = "sttfstate2419"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_oidc             = true
  }
}
