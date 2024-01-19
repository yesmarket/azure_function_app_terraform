provider "azurerm" {
	version = "~> 3.0"
	alias = ""
	tenant_id = var.tenant_id
	client_id = var.client_id
	client_secret = var.client_secret
	subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "this" {
  name     = ""
  location = ""
}

# Create Azure Storage Account required for Function App
resource azurerm_storage_account "this" {
  name                     = ""
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create Azure App Service Plan using Consumption pricing
resource azurerm_app_service_plan "this" {
  name                = ""
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# Create an Azure Function App
resource azurerm_function_app "primary" {
  name                       = ""
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location

  app_service_plan_id        = azurerm_app_service_plan.this.id
  
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  
  os_type                    = "linux"
  version                    = "~3"
  
  site_config {
    always_on = true
  }
}
