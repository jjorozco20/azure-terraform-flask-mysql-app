output "vm_public_ip" {
  description = "Public IP of the Flask VM"
  value       = azurerm_public_ip.flask_vm_ip.ip_address
}

output "mysql_private_ip" {
  description = "Private IP of MySQL server"
  value       = azurerm_mysql_flexible_server.mysql_server.fqdn
  sensitive   = true
}
