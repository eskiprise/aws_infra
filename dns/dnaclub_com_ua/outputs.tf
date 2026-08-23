output "zone_id" {
  value       = aws_route53_zone.dnaclub.zone_id
  sensitive   = false
  description = "Route 53 hosted zone ID for dnaclub.com.ua"
}

output "name_servers" {
  value       = aws_route53_zone.dnaclub.name_servers
  sensitive   = false
  description = "Set these as dnaclub.com.ua's nameservers at the registrar to delegate DNS to this zone — required before ACM DNS validation can complete"
}

output "prod_certificate_arn" {
  value       = aws_acm_certificate_validation.prod.certificate_arn
  sensitive   = false
  description = "Validated ACM certificate ARN for dnaclub.com.ua + www.dnaclub.com.ua (us-east-1, for the prod CloudFront distribution)"
}

output "dev_certificate_arn" {
  value       = aws_acm_certificate_validation.dev.certificate_arn
  sensitive   = false
  description = "Validated ACM certificate ARN for dev.dnaclub.com.ua (us-east-1, for the dev CloudFront distribution)"
}
