variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }

variable "replication_location" {
  type        = string
  description = "Secondary region for geo-replication"
  default     = "westus2"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "untagged_retention_days" {
  description = "Days to retain untagged manifests before purge (0-365)."
  type        = number
  default     = 30
}
