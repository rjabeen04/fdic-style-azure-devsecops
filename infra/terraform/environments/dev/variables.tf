variable "location" {
  type        = string
  description = "Azure region for dev"
  default     = "eastus"
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "Allowed IP ranges for AKS API server (dev). FDIC-style would be VPN/corp IPs."
  default     = ["0.0.0.0/0"]
}
