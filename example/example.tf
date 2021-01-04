terraform {
  required_version = ">= 0.12.0"
  backend "local" {}
}


variable "region" {
  default = "eu-central-1"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.7.0"

  enable_dns_hostnames = true
  enable_dns_support   = true

  name = "vault-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Terraform = "true"
    App       = "vault"
  }
}

module "vault" {
  source     = "../"
  vpc_id     = module.vpc.vpc_id
  aws_region = var.region

  environment = "dev"

  lb_subnets  = module.vpc.public_subnets
  ec2_subnets = module.vpc.public_subnets
  zone_name   = "gc.crlabs.cloud"

  key_name          = "giulio.calzolari"
  size              = 2
  admin_cidr_blocks = ["93.32.180.190/32"]

  kms_key_id = "c37148b5-490d-4730-b953-2ea56f9779d3"

  extra_tags = {
    Terraform = "true"
    App       = "vault"
  }
}

output "module_vault" {
  value = module.vault
}
