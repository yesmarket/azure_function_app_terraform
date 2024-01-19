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
