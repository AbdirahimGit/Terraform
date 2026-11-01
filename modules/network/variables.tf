variable "name" {
  type        = string
  description = "Name for the security group"
  default     = "wordpress-sg"
}

variable "description" {
  type        = string
  description = "Description for the security group"
  default     = "Security group for the WordPress server"
}

variable "ip_address" {
  type        = string
  description = "CIDR range allowed to SSH, e.g. 203.0.113.25/32"
}