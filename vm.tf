# ------------------------------------------
# Create virtual network Linux VM
# ------------------------------------------

# Data template Bash bootstrapping file
data "template_file" "linux-vm-cloud-init" {
  template = file("azure-user-data.sh")
}

# Get a Static Public IP
resource "azurerm_public_ip" "linux-vm-ip" {
  depends_on=[azurerm_resource_group.rg]
  for_each = {
    for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet
  }
  name                = "linux-${var.network_resource_prefix}-${each.key}-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "network_interface" {
  for_each = {
    for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet
  }
  name                = "${var.network_resource_prefix}-${each.key}-network_interface"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux-vm-ip[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "virtual_machine_a" {
  for_each = {
    for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet 
    if subnet.subnet_key == "subnet-a"
  }
  name                            = "${var.network_resource_prefix}-${each.key}-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2s_v3"
  computer_name                   = "linux-${each.key}-vm"
  admin_username                  = "azureuser"
  admin_password                  = "p@ssword1"
  network_interface_ids = [azurerm_network_interface.network_interface[each.key].id]


  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name = "linux-${each.key}-linux-vm-os-disk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  custom_data    = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  disable_password_authentication = false
}

resource "azurerm_linux_virtual_machine" "virtual_machine" {
  for_each = {
    for subnet in local.network_subnets : "${subnet.network_key}.${subnet.subnet_key}" => subnet
    if subnet.subnet_key == "subnet-b" || subnet.subnet_key == "subnet-c"
  }
  name                            = "${var.network_resource_prefix}-${each.key}-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2s_v3"
  computer_name                   = "linux-${each.key}-vm"
  admin_username                  = "azureuser"
  admin_password                  = "p@ssword1"
  network_interface_ids = [azurerm_network_interface.network_interface[each.key].id]


  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name = "linux-${each.key}-linux-vm-os-disk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  disable_password_authentication = false
}