variable "name" {
  description = "Key Vault name (must be globally unique)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention days."
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Enable purge protection."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public access (enterprise usually false)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}
variable "key_expire_days" {
  description = "How many days until the Key Vault key expires."
  type        = number
  default     = 365
}

# Key config
variable "key_name" {
  description = "Key name."
  type        = string
  default     = "des-key"
}

variable "key_type" {
  description = "Key type."
  type        = string
  default     = "RSA"
}

variable "key_size" {
  description = "Key size."
  type        = number
  default     = 2048
}
