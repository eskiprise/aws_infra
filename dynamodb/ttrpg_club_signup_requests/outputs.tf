output "dynamodb_table_arn" {
  value       = module.dynamodb_table.dynamodb_table_arn
  sensitive   = false
  description = "ARN of DynamoDB table"
  depends_on  = [module.dynamodb_table]
}

output "dynamodb_table_name" {
  value       = module.dynamodb_table.dynamodb_table_id
  sensitive   = false
  description = "Name of DynamoDB table"
  depends_on  = [module.dynamodb_table]
}

output "dynamodb_table_stream_arn" {
  value       = module.dynamodb_table.dynamodb_table_stream_arn
  sensitive   = false
  description = "Stream ARN, consumed by the Notifier Lambda's event source mapping"
  depends_on  = [module.dynamodb_table]
}
