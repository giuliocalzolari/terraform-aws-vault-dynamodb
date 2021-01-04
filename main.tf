data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms_key_policy_document" {

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    actions = [
      "kms:*",
    ]

    resources = [
      "*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "Allow use of the key"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      "*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
  }

  statement {
    sid    = "Allow use of the key for spot"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = [
      "*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot"]
    }
  }

  statement {
    sid    = "Allow use of the key for backup"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = [
      "*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/BackupServiceRole"]
    }
  }

  statement {
    sid    = "Allow use of the key for logs"
    effect = "Allow"

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [
      "*",
    ]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"

    actions = [
      "kms:CreateGrant"
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }

    resources = [
      "*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
  }
}


resource "aws_kms_key" "key" {
  count       = var.kms_key_id == "" ? 1 : 0
  description = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-kms"
  policy      = data.aws_iam_policy_document.kms_key_policy_document.json
}

resource "aws_kms_alias" "key" {
  count         = var.kms_key_id == "" ? 1 : 0
  name          = "alias/${var.environment}-${var.prefix}${var.app_name}${var.suffix}-kms"
  target_key_id = aws_kms_key.key[0].key_id
}

data "aws_kms_key" "by_id" {
  key_id = local.kms_key_id
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}"
  retention_in_days = 90

  kms_key_id = local.kms_key_id

  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-log"),
  )
}

resource "aws_ssm_parameter" "root_token" {
  name   = "/${var.prefix}${var.app_name}${var.suffix}/${var.environment}/root/token"
  type   = "SecureString"
  value  = "init"
  key_id = local.kms_key_id
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "root_pass" {
  name   = "/${var.prefix}${var.app_name}${var.suffix}/${var.environment}/root/pass"
  type   = "SecureString"
  value  = "init"
  key_id = local.kms_key_id
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
