
# Networking variables
variable "azurerm_resource_group_name" {
    default = "deploy-rg"
}

variable "location" {
    default = "East US"
}

variable "azurerm_virtual_network_name" {
    default = "vnet-name"
}

variable "vnet_address_space" {
    default = "10.0.0.0/16"
}

variable "subnet_web_api" {
    default = "public"
}

variable "subnet_server" {
    default = "private"
}

variable "subnet_database" {
    default = "database-subnet"
}

variable "subnet_cache" {
    default = "cache-subnet"
}
#-------------------

# Virtual machines variables
variable "prefix" {
    default = "vm"
}

variable "ssh_key" {
  default = "AAAAB3NzaC1yc2EAAAABJQAAAQEAtxzk6rb2c0oqsB2EQXaX+PFqXWpa3OskN4s8akHDskPE5ZtXQZI/wZE54pmwlP8rsm+o5e33IdZ3Ps+vm/4IvBJuNbxvJJAQn4n7AF7UR6pX5+HHUVe22kpslfIxM02MhgfbsJ8+TcZzkTh+XXgZzdPt7JTSV0Hte96vLUQekIroi0mUMXu8jnygS2pWquzbaOfff1ep4nHYTdDaHYvQz81CIZyGLL5nQdXInLtP2X0tew5N76Jgg53nom3iVlmPlqhqLPwp3AiJVEXST0h6ujtEL51HGKTJtsiYE9vGCX5HEebqHukEIndThivow3MZ6ClDvY2bI8fwEE/lM0BRWQ=="
}
variable "admin_username" {
  default = "vm-user"
}

variable "count_index"{
  default = 1
}
variable "vm_size" {
  default = "Standard_DS1_v2"
}

variable "source_image" {
  description = "image reference"
  type = list(object({
    publisher           = string
    offer               = string
    sku                 = string
    version             = string
  }))

  default = [{
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }]
}

variable "os_disk_storage_account_type" {
  default = "Standard_LRS"
}

variable "os_disk_storage_caching" {
  default = "ReadWrite"
}