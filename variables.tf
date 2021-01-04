variable "aws_region" {
  description = "AWS region to launch servers."
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "VPC Id"
}

variable "environment" {
  default     = "dev"
  type        = string
  description = "Environment Name (e.g. dev, test, uat, prod, etc..)"
}

variable "app_name" {
  default     = "vault"
  type        = string
  description = "Application name N.1 (e.g. vault, secure, store, etc..)"
}

variable "prefix" {
  default     = ""
  type        = string
  description = "Prefix to add on all resources"
}

variable "suffix" {
  default     = ""
  type        = string
  description = "Suffix to add on all resources"
}


variable "key_name" {
  default     = null
  type        = string
  description = "EC2 key pair name"
}

variable "arch" {
  default     = "arm64"
  type        = string
  description = "EC2 Architecture arm64/x86_64 (arm64 is suggested)"
}

variable "vault_version" {
  default     = "1.6.1"
  type        = string
  description = "Vault version to install"
}


locals {
  arch_version = {
    "x86_64" = "amd64"
    "arm64"  = "arm64"
  }

  kms_key_id = var.kms_key_id == "" ? aws_kms_key.key[0].key_id : var.kms_key_id
}

# Additional tags to apply to all tagged resources.
variable "extra_tags" {
  type        = map(string)
  description = "Additional Tag to add"
}

variable "internal" {
  default     = false
  type        = bool
  description = "ALB internal/public flag"
}

variable "ec2_subnets" {
  default     = []
  type        = list(string)
  description = "ASG Subnets"
}

variable "lb_subnets" {
  default     = []
  type        = list(string)
  description = "ALB Subnets"
}


variable "zone_name" {
  type        = string
  default     = ""
  description = "Public Route53 Zone name for DNS and ACM validation"
}

variable "kms_key_id" {
  default     = ""
  type        = string
  description = "KMS Key Id for vault Auto-Unseal"
}

variable "instance_type" {
  default     = "a1.medium"
  type        = string
  description = "EC2 Instance Size"
}

variable "root_volume_size" {
  default     = "8"
  type        = string
  description = "EC2 ASG Disk Size"
}

variable "size" {
  description = "ASG Size"
  default     = "2"
  type        = string
}

variable "default_cooldown" {
  default     = "30"
  type        = string
  description = "ASG cooldown time"
}

variable "termination_policies" {
  type        = list(string)
  default     = ["Default"]
  description = "ASG Termination Policy"
}

variable "protect_from_scale_in" {
  default = false
  type    = bool
}

variable "health_check_type" {
  type        = string
  description = "ASG health_check_type"
  default     = "EC2"
}

variable "alb_ssl_policy" {
  type        = string
  description = "ALB ssl policy"
  default     = "ELBSecurityPolicy-FS-1-2-2019-08"
}

variable "admin_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "Admin CIDR Block to access SSH and internal Application ports"
}

variable "recreate_asg_when_lc_changes" {
  description = "Whether to recreate an autoscaling group when launch configuration changes"
  type        = bool
  default     = true
}


variable "actions_alarm" {
  type        = list(string)
  default     = []
  description = "A list of actions to take when alarms are triggered. Will likely be an SNS topic for event distribution."
}

variable "actions_ok" {
  type        = list(string)
  default     = []
  description = "A list of actions to take when alarms are cleared. Will likely be an SNS topic for event distribution."
}