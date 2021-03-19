# Network interface for the work-vm
resource "azurerm_network_interface" "work-vm" {
  name                = "worker-nic${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  count               = var.count_index

  ip_configuration {
    name                          = "work-vm${count.index}"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network security group for the worker vm
resource "azurerm_network_security_group" "work-vm" {
  name                = "worker-nsg${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  count               = var.count_index

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "work-vm" {
network_interface_id      = element(azurerm_network_interface.work-vm.*.id, count.index)
  network_security_group_id = element(azurerm_network_security_group.work-vm.*.id, count.index)
  count               = var.count_index
}

# Virtual machine for the worker server 
resource "azurerm_linux_virtual_machine" "work-vm" {
  name                = "${var.prefix}-worker${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  count               = var.count_index

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_key
    # public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.work-vm[count.index].id
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
    name                 = "worker-OsDisk${count.index}"
    storage_account_type = var.os_disk_storage_account_type
    caching              = var.os_disk_storage_caching
  }

}

# VM extension for the worker vm
resource "azurerm_virtual_machine_extension" "work-vm" {
  name                 = "worker-ext${count.index}"
  virtual_machine_id   = element(azurerm_linux_virtual_machine.work-vm.*.id, count.index)
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  count               = var.count_index

  settings = <<SETTINGS
    {
    "fileUris": ["https://raw.githubusercontent.com/osamaoracle/sh-scripts/master/scripts/worker_vm.ssh"],
    "commandToExecute": "bash worker_vm.sh"
    }
SETTINGS

 
}
