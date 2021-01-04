resource "aws_alb" "main" {

  name = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}"

  internal        = var.internal
  subnets         = var.lb_subnets
  security_groups = [aws_security_group.alb_sg.id]


  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-alb"),
  )

}

resource "aws_alb_listener" "main" {

  load_balancer_arn = aws_alb.main.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.vault.certificate_arn
  ssl_policy        = var.alb_ssl_policy

  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
}



resource "aws_alb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_alb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      host        = "${var.prefix}${var.app_name}${var.suffix}.${data.aws_route53_zone.zone.name}"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_alb_target_group" "main" {
  name_prefix = "vault-"

  port        = 8200
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 5
    matcher             = "200"
    path                = "/v1/sys/health"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = 2
    unhealthy_threshold = 2
  }

  stickiness {
    cookie_duration = 3600
    enabled         = true
    type            = "lb_cookie"
  }

  deregistration_delay = 5

  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-tg"),
  )

}



resource "aws_cloudwatch_metric_alarm" "httpcode_target_5xx_count" {
  alarm_name          = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-TG-high5XXCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Average API 5XX target group error code count is too high"
  alarm_actions       = var.actions_alarm
  ok_actions          = var.actions_ok

  dimensions = {
    "TargetGroup"  = aws_alb_target_group.main
    "LoadBalancer" = aws_alb.main.id
  }
}

resource "aws_cloudwatch_metric_alarm" "httpcode_lb_5xx_count" {
  alarm_name          = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-LB-high5XXCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Average API 5XX load balancer error code count is too high"
  alarm_actions       = var.actions_alarm
  ok_actions          = var.actions_ok

  dimensions = {
    "LoadBalancer" = aws_alb.main.id
  }
}

resource "aws_cloudwatch_metric_alarm" "target_response_time_average" {
  alarm_name          = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-highResponseTime"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Average API response time is too high"
  alarm_actions       = var.actions_alarm
  ok_actions          = var.actions_ok

  dimensions = {
    "TargetGroup"  = aws_alb_target_group.main
    "LoadBalancer" = aws_alb.main.id
  }
}
