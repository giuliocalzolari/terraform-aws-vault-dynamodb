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
  name = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-tg"

  port        = 8200
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 5
    matcher             = "200"
    path                = "/v1/sys/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 2
    unhealthy_threshold = 2
  }

  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }

  deregistration_delay = 5

  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-tg"),
  )
}
