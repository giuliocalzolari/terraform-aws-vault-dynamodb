# Vaul + Consul all in ONE

## Overview

[Hashicorp Vault](https://www.vaultproject.io/) is becoming one of the most popular tools for secret management, every company to improve their security but sometimes setting a Vault it requires some time and deep understanding on how to configure it. To make it easy the journey to AWS Cloud and increase the level of security of all application I've decided to create an out-of-the-box solution to configure the AWS infrastructure and setting up Vault in one click.

## Diagram

<p align="center">
  <img src="https://raw.githubusercontent.com/giuliocalzolari/terraform-aws-vault-dynamodb/master/diagram.png">
</p>



# The solution

- AWS Autoscaling group with Userdata to install Vault, Consul and AWS Cloudwatch Agent.
- Vault with AWSKMS Auto-Unseal
- basic Vault Provisioning
- Export of Vault sensitive parameters in AWS Paramaters Store
- Using AWS ARM instance with a1.medium as default to save cost

## Terraform Version

This module support Terraform `>= 0.12.0`

# Module Input Variables
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| random | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| admin\_cidr\_blocks | Admin CIDR Block to access SSH and internal Application ports | `list(string)` | `[]` | no |
| alb\_ssl\_policy | ALB ssl policy | `string` | `"ELBSecurityPolicy-TLS-1-2-Ext-2018-06"` | no |
| app\_name | Application name N.1 (e.g. vault, secure, store, etc..) | `string` | `"vault"` | no |
| arch | EC2 Architecture arm64/x86\_64 (arm64 is suggested) | `string` | `"arm64"` | no |
| aws\_region | AWS region to launch servers. | `string` | n/a | yes |
| default\_cooldown | ASG cooldown time | `string` | `"30"` | no |
| ec2\_subnets | ASG Subnets | `list(string)` | `[]` | no |
| environment | Environment Name (e.g. dev, test, uat, prod, etc..) | `string` | `"dev"` | no |
| extra\_tags | Additional Tag to add | `map(string)` | n/a | yes |
| health\_check\_type | ASG health\_check\_type | `string` | `"EC2"` | no |
| instance\_type | EC2 Instance Size | `string` | `"a1.medium"` | no |
| internal | ALB internal/public flag | `bool` | `false` | no |
| key\_name | EC2 key pair name | `string` | n/a | yes |
| kms\_key\_id | KMS Key Id for vault Auto-Unseal | `string` | `""` | no |
| lb\_subnets | ALB Subnets | `list(string)` | `[]` | no |
| prefix | Prefix to add on all resources | `string` | `""` | no |
| protect\_from\_scale\_in | n/a | `bool` | `false` | no |
| recreate\_asg\_when\_lc\_changes | Whether to recreate an autoscaling group when launch configuration changes | `bool` | `true` | no |
| root\_volume\_size | EC2 ASG Disk Size | `string` | `"8"` | no |
| size | ASG Size | `string` | `"2"` | no |
| suffix | Suffix to add on all resources | `string` | `""` | no |
| termination\_policies | ASG Termination Policy | `list(string)` | <pre>[<br>  "Default"<br>]</pre> | no |
| vault\_version | Vault version to install | `string` | `"1.6.1"` | no |
| vpc\_id | VPC Id | `string` | n/a | yes |
| zone\_name | Public Route53 Zone name for DNS and ACM validation | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb\_arn | ALB ARN |
| alb\_hostname | ALB DNS |
| iam\_role\_arn | IAM EC2 role ARN |
| kms\_key\_id | KMS key ID |
| root\_pass\_arn | SSM vault root password ARN |
| root\_token\_arn | SSM vault root token ARN |
| vault\_fqdn | Vault DNS |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Why Not Fargate?

Fargate is a new AWS serverless technology for running Docker containers. It was
considered for this project but rejected for several reasons:

1. No support for `IPC_LOCK`. Vault tries to lock its memory so that secret data
   is never swapped to disk. Although it seems unlikely Fargate swaps to disk, the
   lock capability is not provided.

2. Running on EC2 makes configuring Vault easier. The Ansible playbooks or bash included
   with this terraform build the Vault configuration for each server. It would
   be much harder to do this in a Fargate environment with sidecar containers or
   custom Vault images.

3. Running on EC2 makes DNS configuration easier. The Vault redirection method
   means you need to know the separate DNS endpoint names and doing this on Fargate
   is complicated. With EC2 we register some ElasticIPs and use those for the
   individual servers.

Many of these problems could be solved by running Vault in a custom image. However,
it seemed valuable to use the Hashicorp Vault image instead of relying on custom
built ones, so EC2 was chosen as the ECS technology.

# Example

please check the [example folder](./example/).


## Test your solution

Do you want to test your deployment?
Just open your shell, adjust the DNS and kill the primary vault

```
for i in {1..500}
do
   RES=$(curl -s -o /dev/null -w "%{http_code}"  https://vault.[ YOUR DOMAIN ]/ui/)
   echo "[$(date +%T)] HTTP:$RES attemp:$i"
   sleep 1
done
```

in **less than a minute** the standby instance will be available and in **few minutes** the ASG will launch a new node

## License

this repo is licensed under the [WTFPL](LICENSE).

# pre-commit hook

this repo is using pre-commit hook to know more [click here](https://github.com/antonbabenko/pre-commit-terraform)
to manually trigger use this command

```
pre-commit install
pre-commit run --all-files
```

# Issue

if for some reason the ASG is not booting the terraform code get in stuck the only option is to destroy the ASG with this command ` terraform destroy -target module.vault.aws_autoscaling_group.asg `
