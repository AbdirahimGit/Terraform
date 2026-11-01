terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-2"
}

/* Create a VPC
resource "aws_vpc" "terraform_VPC" {
  cidr_block = "10.0.0.0/16"
}
*/

# Look up the default VPC
data "aws_vpc" "default" {
  default = true
}

# Look up the subnets inside that VPC
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#Security group 

resource "aws_security_group" "wordpress" {
  name        = "wordpress-sg"
  description = "Security group for the WordPress server"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "wordpress-sg"
  }
}

#HTTP access port 80
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.wordpress.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

#SSH access from port 22
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.wordpress.id
  cidr_ipv4         = var.ip_address
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

#All access across internet
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.wordpress.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#Finding the AMI

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}






