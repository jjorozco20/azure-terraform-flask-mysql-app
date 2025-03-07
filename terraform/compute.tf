resource "tls_private_key" "flask_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.flask_vm_key.private_key_pem
  filename = "${path.module}/flask_vm_key.pem"
}

resource "azurerm_linux_virtual_machine" "flask_vm" {
  name                  = "flask-vm"
  resource_group_name   = azurerm_resource_group.devops_poc.name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.flask_vm_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.flask_vm_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(<<EOF
#!/bin/bash
set -x  # Enable debug mode
exec > /var/log/userdata.log 2>&1  # Redirect output to a log file

echo "User data script started at $(date)" | tee -a /var/log/userdata.log

# Create startup script
cat << 'EOL' > /usr/local/bin/startup.sh
#!/bin/bash
set -x
exec > /var/log/startup.log 2>&1

echo "Startup script executing at $(date)"

sleep 60
sudo apt-get update
sudo apt-get install -y docker.io

sudo systemctl start docker
sudo systemctl enable docker

echo "Pulling Docker image: jjorozco20/flask-mysql-app:1.0.0"
sudo docker pull jjorozco20/flask-mysql-app:1.0.0

echo "Running Docker container with environment variables:"
echo "MYSQL_USER=${var.mysql_admin_user}"
echo "MYSQL_PASSWORD=${var.mysql_admin_password}"
echo "MYSQL_HOST=${azurerm_mysql_flexible_server.mysql_server.fqdn}"
echo "MYSQL_DB=${var.mysql_dbname}"

sudo docker run -d -p 5001:5001 --name flask-app \
  -e MYSQL_USER="${var.mysql_admin_user}" \
  -e MYSQL_PASSWORD="${var.mysql_admin_password}" \
  -e MYSQL_HOST="${azurerm_mysql_flexible_server.mysql_server.fqdn}" \
  -e MYSQL_DB="${var.mysql_dbname}" \
  jjorozco20/flask-mysql-app:1.0.0

echo "Startup script completed at $(date)"
EOL

# Make script executable
chmod +x /usr/local/bin/startup.sh

# Create systemd service to run script on boot
cat << 'EOL' > /etc/systemd/system/startup.service
[Unit]
Description=Run startup script on first boot
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/startup.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOL

# Enable and start the service
systemctl daemon-reload
systemctl enable startup.service
systemctl start startup.service

echo "User data script completed at $(date)" | tee -a /var/log/userdata.log
EOF
)

  depends_on = [
    azurerm_mysql_flexible_server.mysql_server,
    azurerm_network_interface.flask_vm_nic
  ]
}
