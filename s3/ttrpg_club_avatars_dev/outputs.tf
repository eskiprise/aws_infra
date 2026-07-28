output "bucket_name" {
  value       = aws_s3_bucket.avatars.id
  sensitive   = false
  description = "Avatars bucket name (backend AVATAR_BUCKET env var)"
}

output "bucket_arn" {
  value       = aws_s3_bucket.avatars.arn
  sensitive   = false
  description = "Avatars bucket ARN, used for the API Lambda's IAM policy"
}

output "distribution_domain_name" {
  value       = aws_cloudfront_distribution.avatars.domain_name
  sensitive   = false
  description = "Public CDN domain for avatar images (frontend VITE_AVATAR_CDN_BASE_URL, prefixed with https://)"
}
