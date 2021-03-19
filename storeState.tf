terraform {
backend "azurerm" {
resource_group_name = "cloud-shell-storage-westeurope"
storage_account_name = "csb1003bffd892dc5ed"
container_name = "tfstate"
key = "terraform.tfstate"
}
}