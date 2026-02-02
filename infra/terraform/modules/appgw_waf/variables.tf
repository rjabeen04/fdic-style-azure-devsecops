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

variable "tags" {
  type        = map(string)
  default     = {}
}
