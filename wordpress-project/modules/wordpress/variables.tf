variable "db_name" {
  type        = string
  description = "Name of the WordPress database"
  default     = "wordpress"
}

variable "db_user" {
  type        = string
  description = "Database user for WordPress"
  default     = "wpuser"
}

variable "db_password" {
  type        = string
  description = "Database password for the WordPress user"
  sensitive   = true
}