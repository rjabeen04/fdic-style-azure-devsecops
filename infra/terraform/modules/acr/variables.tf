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
