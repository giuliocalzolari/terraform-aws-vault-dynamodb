
data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = [var.arch]
  }
}


data "template_file" "vault" {
  template = file("${path.module}/userdata.tpl")

  vars = {
    kms_key      = local.kms_key_id
    vault_url    = "https://releases.hashicorp.com/vault/${var.vault_version}/vault_${var.vault_version}_linux_${local.arch_version[var.arch]}.zip"
    aws_region   = var.aws_region
    arch_version = local.arch_version[var.arch]
    cluster_size = var.size
    app_name     = "${var.prefix}${var.app_name}${var.suffix}"
    environment  = var.environment
  }
}


resource "random_integer" "asg_name" {
  count = var.recreate_asg_when_lc_changes ? 1 : 0

  min = 10
  max = 99

  keepers = {
    # Generate a new pet name each time we switch launch configuration
    lc_name = element(concat(aws_launch_configuration.lc.*.name, [""]), 0)
  }
}


/*
 * Create Launch Configuration
 */
resource "aws_launch_configuration" "lc" {
  image_id             = data.aws_ami.ami.id
  name_prefix          = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-"
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_instance.id
  security_groups      = [aws_security_group.ec2.id]
  user_data            = data.template_file.vault.rendered
  key_name             = var.key_name
  root_block_device {
    volume_size = var.root_volume_size
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*
 * Create Auto-Scaling Group
 */
resource "aws_autoscaling_group" "asg" {
  // name_prefix               = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-"
  name_prefix = "${join(
    "-",
    compact(
      [
        var.environment,
        var.prefix,
        var.app_name,
        var.suffix,
        var.recreate_asg_when_lc_changes ? element(concat(random_integer.asg_name.*.id, [""]), 0) : "",
      ],
    ),
  )}-"

  vpc_zone_identifier       = var.ec2_subnets
  min_size                  = var.size
  max_size                  = var.size
  min_elb_capacity          = 1
  health_check_type         = var.health_check_type
  force_delete              = true
  health_check_grace_period = 300

  default_cooldown     = var.default_cooldown
  termination_policies = var.termination_policies
  launch_configuration = aws_launch_configuration.lc.id

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "environment_name"
    value               = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.extra_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  protect_from_scale_in = var.protect_from_scale_in
  target_group_arns     = [aws_alb_target_group.main.arn]
  lifecycle {
    create_before_destroy = true
  }
}




resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name  = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-high-cpu-utilization"
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  threshold           = 90
  unit                = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  count = format("%.1s", var.instance_type) == "t" ? 1 : 0

  alarm_name  = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-low-cpu-credit-balance"
  namespace   = "AWS/EC2"
  metric_name = "CPUCreditBalance"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Minimum"
  threshold           = 10
  unit                = "Count"
}
