

# Network security group for the webserver vmss
resource "azurerm_network_security_group" "vmss-webserver" {
  name                = "vmsss-api-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Virtual machine scale set for the webserver vmss
resource "azurerm_linux_virtual_machine_scale_set" "vmss-webserver" {
  name                = "${var.prefix}ss-webserver"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.vm_size
  instances           = 1
  admin_username      = var.admin_username


  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_key
    # public_key = file("~/.ssh/id_rsa.pub")
  }


  dynamic "source_image_reference" {
    for_each = var.source_image
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  os_disk {
    storage_account_type = var.os_disk_storage_account_type
    caching              = var.os_disk_storage_caching
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.main.primary_blob_endpoint
  }

  network_interface {
    name                      = "vmss-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.vmss-webserver.id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.public.id
    }
  }

  lifecycle {
    ignore_changes = [instances]
  }
}

resource "azurerm_monitor_autoscale_setting" "vmss-webserver" {
  name                = "autoscale-webserver"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss-webserver.id

  profile {
    name = "AutoScale"

    capacity {
      default = 3
      minimum = 1
      maximum = 5
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss-webserver.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss-webserver.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 45
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}
# Virtual machine scale set extension for the webserver vmss
resource "azurerm_virtual_machine_scale_set_extension" "vmss-webserver" {
  name                         = "vmss-webserver-ext"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss-webserver.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.0"
  auto_upgrade_minor_version = true
  settings = jsonencode({
    "fileUris" : ["https://raw.githubusercontent.com/osamaoracle/terraform-project/master/scripts/vmss_webserver.ssh"],
    "commandToExecute" : "bash vmss_webserver.sh"
    # "commandToExecute" = "echo $HOSTNAME"
  })
}

# Virtual machine scale set extension for the api vmss
resource "azurerm_virtual_machine_scale_set_extension" "DependencyAgentLinux-webserver" {
  name                         = "DependencyAgentLinux"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss-webserver.id
  publisher                    = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                         = "DependencyAgentLinux"
  type_handler_version         = "9.10"
  auto_upgrade_minor_version   = true

  settings = <<SETTINGS
    {
    }
SETTINGS
}

# Virtual machine scale set extension for the api vmss
resource "azurerm_virtual_machine_scale_set_extension" "MMAExtension-webserver" {
  name                         = "MMAExtension"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss-webserver.id
  publisher                    = "Microsoft.EnterpriseCloud.Monitoring"
  type                         = "OmsAgentForLinux"
  type_handler_version         = "1.7"
  auto_upgrade_minor_version   = true

  settings = <<SETTINGS
    {
    }
SETTINGS
}
