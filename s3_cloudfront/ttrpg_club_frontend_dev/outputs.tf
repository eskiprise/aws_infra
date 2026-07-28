output "bucket_name" {
  value       = aws_s3_bucket.frontend.id
  sensitive   = false
  description = "S3 bucket to sync the dev frontend build output into"
}

output "distribution_id" {
  value       = aws_cloudfront_distribution.frontend.id
  sensitive   = false
  description = "CloudFront distribution ID, for cache invalidation on deploy"
}

output "distribution_domain_name" {
  value       = aws_cloudfront_distribution.frontend.domain_name
  sensitive   = false
  description = "Public URL of the deployed dev site"
}
