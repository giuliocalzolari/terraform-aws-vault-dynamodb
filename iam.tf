/*== ec2 CLUSTER INSTANCES IAM ==*/
resource "aws_iam_instance_profile" "ec2_instance" {
  name = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-ec2-profile"
  role = aws_iam_role.ec2_instance.name
}

resource "aws_iam_role" "ec2_instance" {
  name               = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-ec2-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance.json
  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-ec2-role")
  )
}

data "aws_iam_policy_document" "ec2_instance" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ec2_role_policy" {
  name   = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-ec2-role-policy"
  role   = aws_iam_role.ec2_instance.id
  policy = data.aws_iam_policy_document.ec2_role_policy.json
}



data "aws_iam_policy_document" "ec2_role_policy" {

  statement {
    sid       = "VaultKMSUnseal"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "ec2:DescribeInstances"
    ]
  }
  statement {
    sid    = "allowParameterStore"
    effect = "Allow"
    resources = [
      "arn:aws:ssm:*:*:parameter/${var.prefix}${var.app_name}${var.suffix}/${var.environment}/*"
    ]
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter"
    ]
  }

  statement {
    sid    = "allowLoggingToCloudWatch"
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    sid    = "allowDynamoDB"
    effect = "Allow"
    resources = [
      aws_dynamodb_table.dynamodb_table.arn
    ]
    actions = [
      "dynamodb:DescribeLimits",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource",
      "dynamodb:DescribeReservedCapacityOfferings",
      "dynamodb:DescribeReservedCapacity",
      "dynamodb:ListTables",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:CreateTable",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:GetRecords",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
      "dynamodb:Scan",
      "dynamodb:DescribeTable"
    ]
  }
}


resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
