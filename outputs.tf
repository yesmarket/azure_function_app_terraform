output "function_app_name" {
  value       = azurerm_linux_function_app.gpg.name
  description = "Deployed function app name"
}

output "function_app_hostname" {
  value       = azurerm_linux_function_app.gpg.default_hostname
  description = "Deployed function app hostname"
}
