# Route 53 Domains doesn't sell .com.ua (confirmed against AWS's own supported-TLD
# list) — the domain itself is registered elsewhere. This zone just needs the
# registrar's nameservers pointed at `name_servers` (see outputs.tf) to take over DNS.
resource "aws_route53_zone" "dnaclub" {
  name = "dnaclub.com.ua"

  tags = {
    Terraform = "true"
    Project   = "ttrpg-club"
  }
}

# --- Certificates -----------------------------------------------------------
# Both DNS-validated (auto-renewing, no manual cert rotation ever) and requested in
# us-east-1 specifically because CloudFront requires that region regardless of where
# the rest of this project's infra lives (eu-west-2).

resource "aws_acm_certificate" "prod" {
  provider                  = aws.us_east_1
  domain_name               = "dnaclub.com.ua"
  subject_alternative_names = ["www.dnaclub.com.ua"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Terraform = "true"
    Project   = "ttrpg-club"
  }
}

resource "aws_route53_record" "prod_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.prod.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.dnaclub.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "prod" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.prod.arn
  validation_record_fqdns = [for r in aws_route53_record.prod_cert_validation : r.fqdn]
}

resource "aws_acm_certificate" "dev" {
  provider          = aws.us_east_1
  domain_name       = "dev.dnaclub.com.ua"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Terraform = "true"
    Project   = "ttrpg-club"
  }
}

resource "aws_route53_record" "dev_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.dev.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.dnaclub.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "dev" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.dev.arn
  validation_record_fqdns = [for r in aws_route53_record.dev_cert_validation : r.fqdn]
}

# --- Alias records ------------------------------------------------------------
# ALIAS (not CNAME) because dnaclub.com.ua is an apex domain — DNS doesn't allow a
# plain CNAME there. www points at the same prod distribution as the apex; the actual
# www -> apex redirect happens in a CloudFront Function on that distribution, not here.

# AWS's fixed, universal hosted zone ID for Route 53 ALIAS records that target ANY
# CloudFront distribution — same value for every distribution on every AWS account,
# documented by AWS and never changes. Hardcoded (not read from the frontend modules'
# remote state) specifically so this module has no dependency on those modules' state
# existing yet, breaking what would otherwise be a circular dependency: the frontend
# modules' own viewer_certificate blocks need THIS module's cert ARNs, so this module
# applying first is required, and it can only do that if it doesn't also need
# something back from them first.
locals {
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2"
}

resource "aws_route53_record" "apex_a" {
  zone_id = aws_route53_zone.dnaclub.zone_id
  name    = "dnaclub.com.ua"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.frontend_prod.outputs.distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = aws_route53_zone.dnaclub.zone_id
  name    = "dnaclub.com.ua"
  type    = "AAAA"

  alias {
    name                   = data.terraform_remote_state.frontend_prod.outputs.distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.dnaclub.zone_id
  name    = "www.dnaclub.com.ua"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.frontend_prod.outputs.distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = aws_route53_zone.dnaclub.zone_id
  name    = "www.dnaclub.com.ua"
  type    = "AAAA"

  alias {
    name                   = data.terraform_remote_state.frontend_prod.outputs.distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "dev_a" {
  zone_id = aws_route53_zone.dnaclub.zone_id
  name    = "dev.dnaclub.com.ua"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.frontend_dev.outputs.distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "dev_aaaa" {
  zone_id = aws_route53_zone.dnaclub.zone_id
  name    = "dev.dnaclub.com.ua"
  type    = "AAAA"

  alias {
    name                   = data.terraform_remote_state.frontend_dev.outputs.distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
