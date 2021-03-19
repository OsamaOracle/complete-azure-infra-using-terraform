provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.azurerm_resource_group_name
    location                 = var.location
}

resource "azurerm_storage_account" "main" {
  name                     = "diastraccname"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

}

resource "azurerm_virtual_network" "main" {
  name                = var.prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "public" {
  name                 = var.subnet_web_api
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private" {
  name                 = var.subnet_server
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = var.subnet_database
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = ["10.0.4.0/24"]
}
resource "azurerm_subnet" "cache" {
  name                 = var.subnet_cache
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = ["10.0.3.0/24"]
}