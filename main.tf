terraform {
  required_version = ">= 0.12.0"
}

resource "aws_kms_key" "key" {
  count       = var.kms_key_id == "" ? 1 : 0
  description = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-kms"
}

resource "aws_kms_alias" "key" {
  count         = var.kms_key_id == "" ? 1 : 0
  name          = "alias/${var.environment}-${var.prefix}${var.app_name}${var.suffix}-kms"
  target_key_id = aws_kms_key.key[0].key_id
}


resource "aws_cloudwatch_log_group" "logs" {
  name              = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}"
  retention_in_days = 90

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


resource "aws_dynamodb_table" "dynamodb_table" {
  name         = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Path"
  range_key    = "Key"
  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }

  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-dynamodb"),
  )
}
