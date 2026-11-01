output "vpc_id" {
  value       = data.aws_vpc.default.id
  description = "The ID of the defualt VPC."
}

output "subnet_id" {
  value       = data.aws_subnets.default_subnets.ids[0]
  description = "The ID of the first default subnet."
}

output "ami_id" {
  description = "Latest Amazon Linux 2023 AMI ID"
  value       = data.aws_ami.amazon_linux.id
}