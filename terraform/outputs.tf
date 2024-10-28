# Output the Resource Group name
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

# Output the Virtual Network name
output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

# Output the Subnet name
output "subnet_name" {
  description = "The name of the subnet"
  value       = azurerm_subnet.main.name
}

# Output the Public IP address
output "public_ip_address" {
  description = "The IP address of the Public IP resource"
  value       = azurerm_public_ip.main.ip_address
}

# Output the Load Balancer Name
output "load_balancer_name" {
  description = "The name of the load balancer"
  value       = azurerm_lb.main.name
}

# Output the Load Balancer Frontend IP Configuration
output "load_balancer_frontend_ip" {
  description = "The frontend IP configuration name for the load balancer"
  value       = azurerm_lb.main.frontend_ip_configuration[0].name
}

# Output the VM Scale Set Name
output "vmss_name" {
  description = "The name of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}

# Output the Backend Address Pool ID for the Load Balancer
output "backend_address_pool_id" {
  description = "The ID of the Load Balancer Backend Address Pool"
  value       = azurerm_lb_backend_address_pool.bpepool.id
}
