variable "loc"{
    type        = string
}
variable "rgfirewall"{
    type        = string
}
variable "vnetfirewall"{
    type        = string
}
variable "pass"{
    type        = string
}
resource "azurerm_resource_group" "rgwindows10" {
  name = "rgt-windows10"
  location = var.loc
}

resource "azurerm_subnet" "sbw10"  {
    name           = "sbw10"
    resource_group_name  = var.rgfirewall
    virtual_network_name = var.vnetfirewall
    address_prefixes = ["172.16.1.0/25"]
  }

resource "azurerm_public_ip" "publicaw10" {
    name                         = "publicaw10"
    location            = var.loc
    resource_group_name          = azurerm_resource_group.rgwindows10.name
    allocation_method = "Dynamic"
}
# tarjeta de red unica de w10
resource "azurerm_network_interface" "nic_w10" {
    name                = "nicw10"
    location            = var.loc
    resource_group_name  = azurerm_resource_group.rgwindows10.name
    enable_ip_forwarding = "false"
	ip_configuration {
        name                          = "Nicw10"
        subnet_id                     = azurerm_subnet.sbw10.id
        private_ip_address_allocation = "Dynamic"
        primary = true
		public_ip_address_id = azurerm_public_ip.publicaw10.id
    }
}
resource "azurerm_storage_account" "w10esce" {
    name                        = "w10esce"
    resource_group_name         = azurerm_resource_group.rgwindows10.name
    location                    = var.loc
    account_tier                = "Standard"
    account_replication_type    = "LRS"

}

resource "azurerm_virtual_machine" "win10autoclient" {
 
    name                           = "Win10"
    location                    = var.loc
    resource_group_name            = azurerm_resource_group.rgwindows10.name
    network_interface_ids          = [azurerm_network_interface.nic_w10.id]
    vm_size                        = "Standard_B2ms"
    delete_os_disk_on_termination  = "true"
#--- Base OS Image ---
   storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "rs5-pro"
    version   = "latest"
  }
#--- Disk Storage Type
  storage_os_disk {
    name              = "disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    os_type           = "Windows"
  }
#--- Define password + hostname ---
  os_profile {
    computer_name  = "Windows10"
    admin_username = "cloudmss"
    admin_password = var.pass
  }
#---
  os_profile_windows_config {
    enable_automatic_upgrades = false
    provision_vm_agent = true
  }
#-- Windows VM Diagnostics 
  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.w10esce.primary_blob_endpoint
  }
}


output "rgw10"{
  value = azurerm_resource_group.rgwindows10.name
  description ="Grupo de Windows 10"
}
output "w10publica"{
  value = azurerm_public_ip.publicaw10.ip_address
  description ="Ip publica Windows 10"
}

output "sbw10"{
  value = azurerm_subnet.sbw10.id
  description ="Subnet Windows 10"
}