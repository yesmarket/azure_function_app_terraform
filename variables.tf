variable "tenant_id" {
  type        = string
  description = "(Required) AAD tennant ID"
}

variable "client_id" {
  type        = string
  description = "(Required) Azure service principal client ID"
}

variable "client_secret" {
  type        = string
  description = "(Required) Azure service principal client secret"
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "(Required) Azure subscription ID"
}

variable "key_vault_full_access_users" {
  type        = map(string)
  description = "(Required) AAD users (object IDs) with full access to key vault certificates, keys, and secrets"
}

variable "gpg_key_vault_secrets" {
  type        = map(string)
  description = "(Required) Azure Key Vault secrets for gpg encryption/signing and decryption/verification"
}
