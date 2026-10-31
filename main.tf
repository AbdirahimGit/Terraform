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




