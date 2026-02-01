variable "name" {
  description = "Virtual Network (VNet) name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where VNet and subnets will be created."
  type        = string
}

variable "nsg_name_prefix" {
  description = "Prefix used to name NSGs (defaults to VNet name)."
  type        = string
  default     = null
}


variable "address_space" {
  description = "VNet address space."
  type        = list(string)
}

variable "subnets" {
  description = <<EOT
Map of subnets to create.
Example:
subnets = {
  aks = { address_prefixes = ["10.10.1.0/24"], private_endpoint_policies_disabled = false }
  private_endpoints = { address_prefixes = ["10.10.2.0/24"], private_endpoint_policies_disabled = true }
}
EOT

  type = map(object({
    address_prefixes                   = list(string)
    private_endpoint_policies_disabled = optional(bool, false)
  }))
}

variable "tags" {
  description = "Tags applied to the VNet."
  type        = map(string)
  default     = {}
}
