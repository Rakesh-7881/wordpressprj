provider "azurerm" {
  features {}
}
# Resource Group
resource "azurerm_resource_group" "wordpress" {
  name     = "rg-wordpress-app"
  location = "eastus"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-wordpress"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.wordpress.location
  resource_group_name = azurerm_resource_group.wordpress.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-wordpress"
  resource_group_name  = azurerm_resource_group.wordpress.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-wordpress"
  location            = azurerm_resource_group.wordpress.location
  resource_group_name = azurerm_resource_group.wordpress.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Subnet NSG association
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Public IP
resource "azurerm_public_ip" "wp_ip" {
  name                = "wp-public-ip"
  location            = azurerm_resource_group.wordpress.location
  resource_group_name = azurerm_resource_group.wordpress.name
  allocation_method   = "Dynamic"
}

# Network Interface
resource "azurerm_network_interface" "wp_nic" {
  name                = "wp-nic"
  location            = azurerm_resource_group.wordpress.location
  resource_group_name = azurerm_resource_group.wordpress.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wp_ip.id
  }
}

# Virtual Machine (Linux, WordPress)
resource "azurerm_linux_virtual_machine" "wp_vm" {
  name                = "wp-vm"
  resource_group_name = azurerm_resource_group.wordpress.name
  location            = azurerm_resource_group.wordpress.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.wp_nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "production"
  }
}

# Azure Database for MySQL
resource "azurerm_mysql_flexible_server" "wp_db" {
  name                   = "wp-mysql-db"
  resource_group_name    = azurerm_resource_group.wordpress.name
  location               = azurerm_resource_group.wordpress.location
  version                = "8.0"
  administrator_login    = "wpadmin"
  administrator_password = "ChangeThisPassword123!"
  sku_name               = "B_Gen5_1"
  storage_mb             = 5120
  backup_retention_days  = 7
  public_network_access_enabled = true
}
