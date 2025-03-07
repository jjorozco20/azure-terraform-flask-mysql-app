# azure-terraform-flask-mysql-app
In this project you will see how to deploy a full infrastructure with 1 Azure VM server using Flexible MySQL server instance and also provisioning the Ubuntu servers with an user data. Have fun.

---

Infrastructure diagram:



---

### Once that you have this repo cloned on your local, these are the requirements to accomplish before you get started: 

---

#### Get a Free Tier Azure account.  

Note: You will need to add a credit/debit card to be able to register. 

#### Install Terraform 

This is the page in where you can find the installation method for your OS 

https://developer.hashicorp.com/terraform/

#### Install Docker 

This is the page in where you can find the installation method for your OS 

https://docs.docker.com/desktop/setup/install/windows-install/ 

#### Install Azure CLI 

You can follow their page based on your OS 

Create Azure Service Principal to authenticate using it.
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

Then, it's going to print this output:

```

{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "terraform-sp",
  "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

```
Save these credentials securely!

Open `poc.auto.tfvars` and then edit those values here:

```

subscription_id    = "your-subscription-id"
tenant_id          = "your-tenant-id"
client_id          = "appId"
client_secret      = "password"
resource_group_name   = "devops-poc"
location              = "centralus" # worked for me
vm_size               = "Standard_B1s" # Free tier elegible
admin_username        = "azureuser" # Random, change it at your will
mysql_admin_user      = "mysqladmin" # Random, change it at your will
mysql_admin_password = "Testpassword!12" # Random, change it at your will
mysql_dbname         = "devops-mysql-flexible-server1222134" # Random, change it at your will

```

### Once that you are done with that

You can run `terraform plan`, `terraform apply` and to destroy it `terraform destroy`.


## Troubleshooting
You tried to do `terraform destroy` and you are encountering that you can't delete 3 resources (private_subnet, vnet and  resource_group), so you went into Azure Portal and also you did notice that even clicking into delete resource group is not working at all. You are stuck. This is because we delegated to mysql flexible server that private subnet to use it as their communication channel, so we are not putting that rule to work now. Go to variables and disable the delegation by changing the default value of this variable:

```

# If you are going to do a terraform destroy, change default value to false.
variable "enable_mysql_delegation" {
  description = "Enable delegation for MySQL Flexible Server"
  type        = bool
  default     = true
}
```

If it's not working, do this workaround instead: 

```
az network vnet subnet update `
  --name [private-subnet-name] `
  --vnet-name [devops-vnet-name] `
  --resource-group [devops-poc-name] `
  --remove delegations

```
