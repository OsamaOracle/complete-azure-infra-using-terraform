
resource "azurerm_public_ip" "vmss" {
  name                = "PublicIPForLB"
  location            = var.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "vmss" {
  name                = "TestLoadBalancer"
  location            = var.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.vmss.name
    public_ip_address_id = azurerm_public_ip.vmss.id
  }
}

resource "azurerm_lb_backend_address_pool" "vmss" {
  name                = "backend-pool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.vmss.id
}

resource "azurerm_lb_nat_pool" "vmss" {
  name                           = "nat-pool"
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.vmss.id
  frontend_ip_configuration_name = azurerm_public_ip.vmss.name
  protocol                       = "Tcp"
  frontend_port_start            = 80
  frontend_port_end              = 90
  backend_port                   = 8080
}

resource "azurerm_lb_probe" "vmss" {
  name                = "web-probe"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.vmss.id
  port                = 80
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "vmss" {
  name                            = "LBRule"
  resource_group_name             = azurerm_resource_group.main.name
  loadbalancer_id                 = azurerm_lb.vmss.id
  probe_id                        = azurerm_lb_probe.vmss.id
  backend_address_pool_id         = azurerm_lb_backend_address_pool.vmss.id
  frontend_ip_configuration_name  = "PublicIPAddress"
  protocol                        = "TCP"
  frontend_port                   = 443
  backend_port                    = 80
}
