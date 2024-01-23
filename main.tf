resource "azurerm_resource_group" "this" {
  name     = "gpg_fn_app_rg"
  location = "Australia East"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "gpg-logs"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "this" {
  name                = "gpg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  application_type    = "web"
  retention_in_days   = 30
  workspace_id        = azurerm_log_analytics_workspace.this.id
}

resource "azurerm_storage_account" "this" {
  name                     = "gpg"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "this" {
  name                = "gpg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "gpg" {
  name                = "gpg-fn"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  service_plan_id = azurerm_service_plan.this.id

  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE       = "1",
    FUNCTIONS_WORKER_RUNTIME       = "dotnet",
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.this.instrumentation_key,
    AzureWebJobsDisableHomepage    = "true",
  }

  site_config {
    cors {
      allowed_origins = ["*", "https://portal.azure.com"]
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

data "local_file" "function_app_zip" {
  filename = "${path.root}/function-app.zip"
}

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = "az webapp deployment source config-zip --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_linux_function_app.gpg.name} --src ${data.local_file.function_app_zip.filename}"
  }
  triggers = {
    hash = data.local_file.function_app_zip.content_md5
  }
}

resource "azurerm_key_vault" "this" {
  name                        = "gpg-vault"
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "full_access_users" {

  for_each = var.key_vault_full_access_users

  key_vault_id = azurerm_key_vault.this.id

  tenant_id = var.tenant_id
  object_id = each.value

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]

  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
  ]

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]

  storage_permissions = [
    "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
  ]
}

resource "azurerm_key_vault_access_policy" "get_secrets_users" {

  key_vault_id = azurerm_key_vault.this.id

  tenant_id = var.tenant_id
  object_id = azurerm_linux_function_app.gpg.identity.0.principal_id

  secret_permissions = [
    "Get"
  ]
}

resource "azurerm_role_assignment" "gpg_fn_app_managed_identity" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_function_app.gpg.identity.0.principal_id
}

resource "azurerm_key_vault_secret" "this" {
  for_each     = var.gpg_key_vault_secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_key_vault_access_policy.full_access_users
  ]
}
