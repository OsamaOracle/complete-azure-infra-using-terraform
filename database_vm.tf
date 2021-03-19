# Network interface for the database-vm
resource "azurerm_network_interface" "database-vm" {
  name                = "database-nic${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  count               = var.count_index

  ip_configuration {
    name                          = "database-vm${count.index}"
    subnet_id                     = azurerm_subnet.database.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network security group for the database vm
resource "azurerm_network_security_group" "database-vm" {
    name                = "database-nsg${count.index}"
    location            = var.location
    resource_group_name = azurerm_resource_group.main.name
    count               = var.count_index

    security_rule {
        name                       = "SSH"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

} 

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "database-vm" {
    network_interface_id      = element(azurerm_network_interface.database-vm.*.id, count.index)
    network_security_group_id = element(azurerm_network_security_group.database-vm.*.id, count.index)
  count               = var.count_index
}

# Virtual machine for the database server 
resource "azurerm_linux_virtual_machine" "database-vm" {
  name                            = "${var.prefix}-database${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  count               = var.count_index

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_key
    # public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.database-vm[count.index].id
  ]

  dynamic "source_image_reference" {
      for_each = var.source_image
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }
 boot_diagnostics {
        storage_account_uri = azurerm_storage_account.main.primary_blob_endpoint
    }
  os_disk {
    name = "database-OsDisk${count.index}"
    storage_account_type = var.os_disk_storage_account_type
    caching              = var.os_disk_storage_caching
  }

}

# VM extension for the database vm
resource "azurerm_virtual_machine_extension" "database-vm" {
  name                 = "database-ext${count.index}"
  virtual_machine_id   = element(azurerm_linux_virtual_machine.database-vm.*.id, count.index)
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  count               = var.count_index

  settings = <<SETTINGS
    {
    "fileUris": ["https://raw.githubusercontent.com/osamaoracle/sh-scripts/master/scripts/database_vm.ssh"],
    "commandToExecute": "bash database_vm.sh"
    }
SETTINGS
}