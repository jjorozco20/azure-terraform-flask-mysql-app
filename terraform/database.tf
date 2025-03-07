resource "azurerm_mysql_flexible_server" "mysql_server" {
  name                   = var.mysql_dbname
  resource_group_name    = azurerm_resource_group.devops_poc.name
  location               = var.location
  administrator_login    = var.mysql_admin_user
  administrator_password = var.mysql_admin_password
  version                = "8.0.21"

  sku_name               = "B_Standard_B1ms"  # Adjust as needed for Free Tier compatibility
  storage {
    size_gb = 20  # Minimum allowed for MySQL Flexible Server (5 GB)
  }

  tags = {
    environment = "dev"
  }

  delegated_subnet_id = azurerm_subnet.private_subnet.id
}
