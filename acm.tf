data "aws_route53_zone" "zone" {
  name         = "${var.zone_name}."
  private_zone = false
}


resource "aws_acm_certificate" "vault" {
  domain_name       = "${var.prefix}${var.app_name}${var.suffix}.${var.zone_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-acm"),
  )

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}


resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.vault.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}


resource "aws_acm_certificate_validation" "vault" {
  certificate_arn         = aws_acm_certificate.vault.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_route53_record" "cname" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.prefix}${var.app_name}${var.suffix}.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_alb.main.dns_name]
}
