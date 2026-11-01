variable "name" {
  type        = string
  description = "Name tag for the instance"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type (x86_64)"
  default     = "t3.micro"
}

variable "subnet_id" {
  type        = string
  description = "Subnet to launch the instance in"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups to attach"
}

variable "user_data" {
  type        = string
  description = "Script to run on first boot"
  sensitive   = true
  default     = null
}

