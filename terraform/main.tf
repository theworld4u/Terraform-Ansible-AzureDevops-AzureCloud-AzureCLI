# Configure the Azure Provider
provider "azurerm" {
  features {}

  subscription_id = var.sub_id
  use_msi = true
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

locals {
  environment              = var.environment                # This will be passed as a variable
  app_name                 = var.app_name
  resource_group_name      = "rg-${local.app_name}-${local.environment}"    # Resource group name based on the environment
  vmss_name                = "vmss-${local.app_name}-${local.environment}"   # VM Scale Set name based on the environment
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.app_name}-vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "${var.app_name}-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "main" {
  name                = "${var.app_name}-pubip-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  domain_name_label   = "rg-${local.environment}"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_lb" "main" {
  name                = "${var.app_name}-lb-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.app_name}-PublicIP-${var.environment}"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "${var.app_name}-BackEndAddressPool-${var.environment}"
}

resource "azurerm_lb_rule" "http" {
  name                            = "http-rule"
  loadbalancer_id                 = azurerm_lb.main.id
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.bpepool.id]
  frontend_ip_configuration_name   = "${var.app_name}-PublicIP-${var.environment}"
  protocol                        = "Tcp"
  frontend_port                   = 80
  backend_port                    = 80
  idle_timeout_in_minutes         = 4
}

resource "azurerm_lb_rule" "ssh" {
  name                            = "ssh-rule"
  loadbalancer_id                 = azurerm_lb.main.id
    backend_address_pool_ids      = [azurerm_lb_backend_address_pool.bpepool.id]
  frontend_ip_configuration_name  = "${var.app_name}-PublicIP-${var.environment}"
  protocol                        = "Tcp"
  frontend_port                   = 22
  backend_port                    = 22
  idle_timeout_in_minutes         = 4
}


resource "azurerm_lb_nat_pool" "lbnatpool" {
  resource_group_name            = azurerm_resource_group.main.name
  name                           = "ssh"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.app_name}-PublicIP-${var.environment}"
}

resource "azurerm_lb_probe" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "${var.app_name}-http-probe-${var.environment}"
  protocol        = "Tcp"
  port            = 80
}

# Create the Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.app_name}-nsg-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Inbound security rules
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 80
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate the NSG with the subnet
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}


resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = "${var.app_name}-vmss-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = "${var.adminuser}"
  admin_password      = "${var.adminpassword}"  # Reference the password variable
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.app_name}-networkinterface-${var.environment}"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.main.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
    }
  }
}
