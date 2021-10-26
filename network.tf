# Configure the Microsoft Azure Provider
locals {
  tags = {
    application = "network-web-service-application"
    environment = "${var.network_resource_prefix}-network"
  }
}

locals {
  # flatten ensures that this local value is a flat list of objects, rather
  # than a list of lists of objects.
  network_subnets = flatten([
    for network_key, network in var.vnt_settings : [
      for subnet_key, subnet in network.subnets : {
        network_key             = network_key
        subnet_key              = subnet_key
        network_id              = azurerm_virtual_network.network_vnet[network_key].id
        address_prefixes        = subnet.address_prefixes
        vnet_name               = network_key
      }
    ]
  ])
  vnets = tomap({ for vnet_key, vnet_id in azurerm_virtual_network.network_vnet : vnet_key => vnet_id.id })
  subs  = tomap({ for sub_key, subnet in azurerm_subnet.subnets : sub_key => { "id" = subnet.id, "vnet_name" = subnet.virtual_network_name }})
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.network_resource_prefix}-resource_group"
  location = var.network_resource_location
  tags = local.tags
}

resource "azurerm_network_ddos_protection_plan" "ddosplan" {
  name                = "ddospplan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# ------------------------------------------
# Create vnet in the Network
# ------------------------------------------

resource "azurerm_virtual_network" "network_vnet" {
  for_each             = var.vnt_settings
  name                = "${each.key}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = each.value.address_space
  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.ddosplan.id
    enable = true
  }
  tags = local.tags
}

# ------------------------------------------
# Create subnets in the Network VNET
# ------------------------------------------

resource "azurerm_subnet" "subnets" {
  #ts:skip=AC_AZURE_0356 Not a security violation
  for_each = {
    for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet
  }
  name                 = each.key
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes
}


# ------------------------------------------
# Create NSG for subnet resources and associate with subnets
# ------------------------------------------

resource "azurerm_network_security_group" "network_security_groups" {
  for_each = {
    for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet
  }
  name                = "${var.network_resource_prefix}-${each.key}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "allow-http"
    description                = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "Allowlinux"
    description                = "Allow linux"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    description                = "Allow SSH"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "network_security_group_associations" {
  for_each = {
    for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet
  }
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.network_security_groups[each.key].id
}