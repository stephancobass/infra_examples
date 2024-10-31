
locals {
  env_app_domain_name = "${var.env_name}" == "prod" ?  var.domain_name_zone : "${var.env_name}.${var.domain_name_zone}"
}

data "aws_route53_zone" "zone" {
  name         = var.domain_name_zone
  private_zone = false
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name_zone
  subject_alternative_names = ["*.${var.domain_name_zone}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.zone.id
}


resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# API record
resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.zone.id
  name    = local.env_app_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.appdns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.zone.id
  name    = "${var.env_name}" == "prod" ?  "api.${var.domain_name_zone}" : "api-${var.env_name}.${var.domain_name_zone}"
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = false
  }
}










