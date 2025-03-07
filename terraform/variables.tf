variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "client_id" {
  description = "Azure Service Principal Application ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  default     = "devops-poc"
  description = "Resource group for the deployment"
}

variable "location" {
  default     = "East US"
  description = "Azure region for resources"
}

variable "vm_size" {
  default     = "Standard_B1s"
  description = "VM size for Flask app"
}

variable "admin_username" {
  default     = "azureuser"
  description = "Admin username for VM"
}

variable "mysql_admin_user" {
  default     = "mysqladmin"
  description = "MySQL admin username"
}

variable "mysql_admin_password" {
  description = "MySQL admin password"
  type        = string
  sensitive   = true
}

variable "mysql_dbname" {
  description = "MySQL dbname"
  type        = string
  default     = "devops-mysql-flexible-server1222134"
}

# If you are going to do a terraform destroy, change default value to false.
variable "enable_mysql_delegation" {
  description = "Enable delegation for MySQL Flexible Server"
  type        = bool
  default     = false
}
