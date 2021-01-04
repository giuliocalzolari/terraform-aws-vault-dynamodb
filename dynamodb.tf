

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

  server_side_encryption {
    enabled     = true
    kms_key_arn = data.aws_kms_key.by_id.arn
  }

  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-dynamodb"),
  )
}


resource "aws_iam_role" "dynamodb_backup" {
  count              = var.dynamodb_backup ? 1 : 0
  name               = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-dynamodb-backup"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "dynamodb_backup_policy" {
  count      = var.dynamodb_backup ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.dynamodb_backup[0].name
}



# AWS Backup vault
resource "aws_backup_vault" "backup_vault" {
  count       = var.dynamodb_backup ? 1 : 0
  name        = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-dynamodb-backup"
  kms_key_arn = data.aws_kms_key.by_id.arn
  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-dynamodb-vault"),
  )
}



resource "aws_backup_plan" "dynamodb_backup_plan" {
  count = var.dynamodb_backup ? 1 : 0
  name  = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-dynamodb-plan"

  rule {
    rule_name         = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-dynamodb-rule"
    target_vault_name = aws_backup_vault.backup_vault[0].name
    schedule          = "cron(0 12 * * ? *)"
    lifecycle {
      delete_after = 30
    }
  }


}

resource "aws_backup_selection" "dynamodb_backup_selection" {
  count        = var.dynamodb_backup ? 1 : 0
  name         = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-dynamodb"
  plan_id      = aws_backup_plan.dynamodb_backup_plan[0].id
  iam_role_arn = aws_iam_role.dynamodb_backup[0].arn

  resources = [
    aws_dynamodb_table.dynamodb_table.arn
  ]
}
