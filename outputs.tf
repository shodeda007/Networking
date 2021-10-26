output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.rg.location
}

output "vnet_name" {
  value = tomap({ for vnet_key, vnet_id in azurerm_virtual_network.network_vnet : vnet_key => vnet_id.name })
}

output "vnet_id" {
  value = tomap({ for vnet_key, vnet_id in azurerm_virtual_network.network_vnet : vnet_key => vnet_id.id })
}

output "subnet_ids" {
  value = tomap({ for subnet_key, subnet in azurerm_subnet.subnets : subnet_key => azurerm_subnet.subnets[subnet_key].id })
}

output "subnet_names" {
  value = tomap({ for subnet_key, subnet in azurerm_subnet.subnets : subnet_key => azurerm_subnet.subnets[subnet_key].name })
}

output "network_interface_id" {
  value = tomap({ for subnet_key, subnet in azurerm_subnet.subnets : subnet_key => azurerm_network_interface.network_interface[subnet_key].id })
}