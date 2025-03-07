# Create Resource Group for the project
resource "azurerm_resource_group" "devops_poc" {
  name     = var.resource_group_name
  location = var.location
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "devops-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_poc.name
  address_space       = ["10.0.0.0/16"]
}

# Create NSG for the Flask VM and allow SSH (port 22)
resource "azurerm_network_security_group" "flask_nsg" {
  name                = "flask-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_poc.name

  security_rule {
    name                       = "allow-ssh"
    direction                  = "Inbound"
    priority                  = 1000
    protocol                  = "Tcp"
    access                    = "Allow"
    source_port_range         = "*"
    destination_port_range    = "22"  # Allow SSH access on port 22
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.devops_poc]  # Ensure NSG is created after the resource group
}

# Security rule to allow Flask app on port 5001
resource "azurerm_network_security_rule" "allow_flask" {
  name                        = "allow-flask-port"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5001"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.devops_poc.name
  network_security_group_name = azurerm_network_security_group.flask_nsg.name

  depends_on = [azurerm_network_security_group.flask_nsg]  # Ensure rule is created after NSG
}

# Create NSG for MySQL, deny external access to port 3306
resource "azurerm_network_security_group" "mysql_nsg" {
  name                = "mysql-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_poc.name

  depends_on = [azurerm_resource_group.devops_poc]  # Ensure NSG is created after the resource group
}

resource "azurerm_network_security_rule" "deny_mysql_external" {
  name                        = "deny-mysql-external"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"  # Deny access to MySQL on port 3306
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.devops_poc.name
  network_security_group_name = azurerm_network_security_group.mysql_nsg.name

  depends_on = [azurerm_network_security_group.mysql_nsg]  # Ensure rule is created after NSG
}

# Create the network interface and associate with the NSG for SSH access
resource "azurerm_network_interface" "flask_vm_nic" {
  name                = "flask-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_poc.name

  ip_configuration {
    name                          = "flask-ipconfig"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.flask_vm_ip.id
  }

  depends_on = [
    azurerm_subnet.public_subnet,
    azurerm_public_ip.flask_vm_ip
  ]
}

resource "azurerm_network_interface_security_group_association" "flask_nsg_association" {
  network_interface_id      = azurerm_network_interface.flask_vm_nic.id
  network_security_group_id = azurerm_network_security_group.flask_nsg.id
}

resource "azurerm_public_ip" "flask_vm_ip" {
  name                = "flask-vm-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_poc.name
  allocation_method   = "Static"
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.devops_poc.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.devops_poc.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  dynamic "delegation" {
    for_each = var.enable_mysql_delegation ? [1] : []
    content {
      name = "mysql-flexible-server-delegation"

      service_delegation {
        name    = "Microsoft.DBforMySQL/flexibleServers"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
          "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
        ]
      }
    }
  }

  lifecycle {
    create_before_destroy = true  # Ensures a new subnet is created before the old one is destroyed
  }
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_private" {
  name                = "allow-private-network"
  server_name         = azurerm_mysql_flexible_server.mysql_server.name
  resource_group_name = azurerm_resource_group.devops_poc.name
  start_ip_address    = "10.0.2.0"
  end_ip_address      = "10.0.2.255"
}
