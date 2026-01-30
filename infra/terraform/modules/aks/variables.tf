variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "dns_prefix" { type = string }
variable "subnet_id" { type = string }

variable "log_analytics_workspace_id" { type = string }
variable "acr_id" { type = string }

variable "disk_encryption_set_id" {
  type        = string
  description = "Disk Encryption Set ID for AKS disk encryption"
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "Allowed IP ranges for AKS API server access"
}

variable "node_count" { type = number, default = 2 }
variable "vm_size" { type = string, default = "Standard_DS2_v2" }

variable "tags" { type = map(string), default = {} }
