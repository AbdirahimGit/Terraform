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

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.EC2.id
}

output "ec2_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.EC2.public_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.EC2.public_dns
}

output "site_url" {
  description = "URL of the WordPress site"
  value       = "http://${aws_instance.EC2.public_ip}"
}