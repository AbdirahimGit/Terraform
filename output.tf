output "site_url" {
  description = "HTTP URL for the WordPress site."
  value       = "http://${module.ec2.ec2_public_ip}"
}

output "ec2_instance_id" {
  description = "ID of the WordPress EC2 instance."
  value       = module.ec2.ec2_instance_id
}

output "ec2_public_ip" {
  description = "Public IPv4 address of the WordPress EC2 instance."
  value       = module.ec2.ec2_public_ip
}

output "public_dns" {
  description = "Public DNS name of the WordPress EC2 instance."
  value       = module.ec2.public_dns
}

output "vpc_id" {
  description = "VPC used by the deployment."
  value       = module.network.vpc_id
}

output "subnet_id" {
  description = "Subnet used by the EC2 instance."
  value       = module.network.subnet_id
}
