terraform {
  backend "azurerm" {
    resource_group_name  = "rg-infra-dev"
    storage_account_name = "storagesampleappdev"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    subscription_id = "*****************"  # Replace with your Azure subscription ID
    use_msi = true
  }
  
}