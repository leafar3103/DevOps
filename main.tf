#Inclusão de verificação de código IAC com Trivy
# Configure Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"

    }
  }
    required_version = ">= 0.14.9"
}
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "rg" {
    name = "rg-terraform"
    location = "eastus2"
    tags = {
        environment = "Production"
        team = "DevOps"
    }
}
# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "vn-terraform"
    address_space       = ["10.1.0.0/16"]
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.rg.name
}
# Create a subnet
resource "azurerm_subnet" "subnet"{

    name = "internal"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.1.1.0/24"]
}
# Create a public IP
resource "azurerm_public_ip" "publicip"{
    name = "pi-vm01"
    location = "eastus2"
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Static"
}
# Create NSG
resource "azurerm_network_security_group" "nsg" {
    name="vm01-nsg"
    location = "eastus2"
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name = "ssh"
        priority = "1001"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}
# Create Network Interface
resource "azurerm_network_interface""nic"{
    name = "vm01-ni"
    location = "eastus2"
    resource_group_name = azurerm_resource_group.rg.name
    # network_security_group_id = azurerm_network_security_group.nsg.id

    ip_configuration {
      name ="vm01-niconfig"
      subnet_id = azurerm_subnet.subnet.id
      private_ip_address_allocation ="dynamic"
      public_ip_address_id = azurerm_public_ip.publicip.id

    }
}
# Create a Linux Virtual Machine
resource "azurerm_virtual_machine" "vm" {
    name = "vm01"
    location = "eastus2"
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic.id]
    vm_size = "Standard_DS1_v2"

    storage_os_disk {
      name ="vm01-osdisk"
      caching="ReadWrite"
      create_option ="FromImage"
      managed_disk_type ="Premium_LRS"
    }
    
    storage_image_reference {
      publisher ="Canonical"
      offer ="UbuntuServer"
      sku="16.04.0-LTS"
      version="latest"
    }
    os_profile {
      computer_name ="vm01"
      admin_username="admaz"
      admin_password="4zur3Cl0ud!"
    }

    os_profile_linux_config {
      disable_password_authentication = false
    }
}


