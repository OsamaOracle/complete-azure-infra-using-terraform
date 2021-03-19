
# Network security group for the api vmss
resource "azurerm_network_security_group" "vmss-api" {
  name                = "vmsss-api-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

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

# Virtual machine scale set for the api vmss
resource "azurerm_linux_virtual_machine_scale_set" "vmss-api" {
  name                = "${var.prefix}ss-api"
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
    network_security_group_id = azurerm_network_security_group.vmss-api.id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.public.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.vmss.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.vmss.id]
    }
  }

    lifecycle {
    ignore_changes = [instances]
  }
  depends_on = [azurerm_lb_probe.vmss]
}

resource "azurerm_monitor_autoscale_setting" "vmss-api" {
  name                = "autoscale-vmss-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss-api.id

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
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss-api.id
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
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss-api.id
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

# Virtual machine scale set extension for the api vmss
resource "azurerm_virtual_machine_scale_set_extension" "vmss-api" {
  name                         = "vmss-api-ext"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss-api.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.0"
  auto_upgrade_minor_version = true
  settings = jsonencode({
    "fileUris" : ["https://raw.githubusercontent.com/osamaoracle/terraform-project/master/scripts/vmss_api.ssh"],
    "commandToExecute" : "bash vmss_api.sh"
    # "commandToExecute" = "echo $HOSTNAME"
  })
}

# Virtual machine scale set extension for the api vmss
resource "azurerm_virtual_machine_scale_set_extension" "healthRepairExtension" {
  name                         = "healthRepairExtension"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss-api.id
  publisher                    = "Microsoft.ManagedServices"
  type                         = "ApplicationHealthLinux"
  type_handler_version         = "1.0"
  auto_upgrade_minor_version   = true

  settings = <<-EOT
    {
      "protocol": "http",
      "port": "80",
      "requestPath": "/check.php"
    }
    EOT
}

# Virtual machine scale set extension for the api vmss
resource "azurerm_virtual_machine_scale_set_extension" "DependencyAgentLinux-api" {
  name                         = "DependencyAgentLinux"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss-api.id
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
resource "azurerm_virtual_machine_scale_set_extension" "MMAExtension-api" {
  name                         = "MMAExtension"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss-api.id
  publisher                    = "Microsoft.EnterpriseCloud.Monitoring"
  type                         = "OmsAgentForLinux"
  type_handler_version         = "1.7"
  auto_upgrade_minor_version   = true

  settings = <<SETTINGS
    {
    }
SETTINGS
}
