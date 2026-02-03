variable "name" {
  type        = string
  description = "Name of the Application Gateway"
}

variable "location" {
  type        = string
}

variable "resource_group_name" {
  type        = string
}

variable "subnet_id" {
  type        = string
  description = "The subnet ID where the App Gateway will reside"
}

variable "sku_name" {
  type        = string
  default     = "WAF_v2"
}

variable "sku_tier" {
  type        = string
  default     = "WAF_v2"
}

variable "ssl_cert_password" {
  type      = string
  sensitive = true
  default   = null
}

# --- MISSING VARIABLES ADDED BELOW ---

variable "backend_fqdn" {
  type        = string
  default     = "musical-volunteer.local"
}

variable "backend_root_cert_data" {
  type        = string
  default     = ""
}

variable "frontend_cert_pfx_base64" {
  type        = string
  default     = ""
}

variable "frontend_cert_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "tags" {
  type        = map(string)
  default     = {}
}
