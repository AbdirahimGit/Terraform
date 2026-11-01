variable "aws_region" {
  description = "AWS region in which to deploy the WordPress server."
  type        = string
  default     = "eu-west-2"
}

variable "ip_address" {
  type        = string
  description = "IP address : CIDR range allowed to SSH to the instance, e.g. 203.0.113.25/32"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance."
  type        = string
  default     = "wordpress-server"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "db_name" {
  description = "Name of the WordPress database."
  type        = string
  default     = "wordpress"
}

variable "db_user" {
  description = "Database user for WordPress."
  type        = string
  default     = "wpuser"
}

variable "db_password" {
  description = "Password for the WordPress database user."
  type        = string
  sensitive   = true
}






