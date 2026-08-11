output "users_table_arn" {
  value = module.users.dynamodb_table_arn
}
output "users_table_name" {
  value = module.users.dynamodb_table_id
}

output "words_table_arn" {
  value = module.words.dynamodb_table_arn
}
output "words_table_name" {
  value = module.words.dynamodb_table_id
}

output "cards_table_arn" {
  value = module.cards.dynamodb_table_arn
}
output "cards_table_name" {
  value = module.cards.dynamodb_table_id
}

output "exercises_table_arn" {
  value = module.exercises.dynamodb_table_arn
}
output "exercises_table_name" {
  value = module.exercises.dynamodb_table_id
}

output "sessions_table_arn" {
  value = module.sessions.dynamodb_table_arn
}
output "sessions_table_name" {
  value = module.sessions.dynamodb_table_id
}
