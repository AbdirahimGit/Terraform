output "vpc_id" {
  value       = data.aws_vpc.default.id
  description = "The ID of the defualt VPC."
}

output "subnet_id" {
  value       = data.aws_subnets.default_subnets.ids[0]
  description = "The ID of the first default subnet."
}

output "security_group_id" {
  description = "ID of the WordPress security group"
  value       = aws_security_group.wordpress.id
}