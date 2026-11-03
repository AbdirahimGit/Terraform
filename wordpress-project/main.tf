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

# The moved blocks preserve the resources already recorded in the original
# root-level Terraform state while they are relocated into child modules.
moved {
  from = aws_security_group.wordpress
  to   = module.network.aws_security_group.wordpress
}

moved {
  from = aws_vpc_security_group_ingress_rule.http
  to   = module.network.aws_vpc_security_group_ingress_rule.http
}

moved {
  from = aws_vpc_security_group_ingress_rule.ssh
  to   = module.network.aws_vpc_security_group_ingress_rule.ssh
}

moved {
  from = aws_vpc_security_group_egress_rule.allow_all_traffic
  to   = module.network.aws_vpc_security_group_egress_rule.allow_all_traffic
}

moved {
  from = aws_instance.EC2
  to   = module.ec2.aws_instance.EC2
}


#Modules

module "network" {
  source     = "./modules/network"
  ip_address = var.ip_address
}

module "wordpress" {
  source      = "./modules/wordpress"
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
}

module "ec2" {
  source             = "./modules/ec2"
  name               = "wordpress-server"
  instance_type      = var.instance_type
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.network.security_group_id]
  user_data          = module.wordpress.user_data
}








