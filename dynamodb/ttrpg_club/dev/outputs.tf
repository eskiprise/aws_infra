output "users_table_arn" {
  value = module.users.dynamodb_table_arn
}
output "users_table_name" {
  value = module.users.dynamodb_table_id
}

output "signup_requests_table_arn" {
  value = module.signup_requests.dynamodb_table_arn
}
output "signup_requests_table_name" {
  value = module.signup_requests.dynamodb_table_id
}

output "game_systems_table_arn" {
  value = module.game_systems.dynamodb_table_arn
}
output "game_systems_table_name" {
  value = module.game_systems.dynamodb_table_id
}

output "games_table_arn" {
  value = module.games.dynamodb_table_arn
}
output "games_table_name" {
  value = module.games.dynamodb_table_id
}

output "game_participants_table_arn" {
  value = module.game_participants.dynamodb_table_arn
}
output "game_participants_table_name" {
  value = module.game_participants.dynamodb_table_id
}

output "game_poll_votes_table_arn" {
  value = module.game_poll_votes.dynamodb_table_arn
}
output "game_poll_votes_table_name" {
  value = module.game_poll_votes.dynamodb_table_id
}

output "game_comments_table_arn" {
  value = module.game_comments.dynamodb_table_arn
}
output "game_comments_table_name" {
  value = module.game_comments.dynamodb_table_id
}

output "settings_table_arn" {
  value = module.settings.dynamodb_table_arn
}
output "settings_table_name" {
  value = module.settings.dynamodb_table_id
}

output "telegram_rating_polls_table_arn" {
  value = module.telegram_rating_polls.dynamodb_table_arn
}
output "telegram_rating_polls_table_name" {
  value = module.telegram_rating_polls.dynamodb_table_id
}

output "telegram_rating_votes_table_arn" {
  value = module.telegram_rating_votes.dynamodb_table_arn
}
output "telegram_rating_votes_table_name" {
  value = module.telegram_rating_votes.dynamodb_table_id
}

output "telegram_feedback_table_arn" {
  value = module.telegram_feedback.dynamodb_table_arn
}
output "telegram_feedback_table_name" {
  value = module.telegram_feedback.dynamodb_table_id
}

output "telegram_xp_ledger_table_arn" {
  value = module.telegram_xp_ledger.dynamodb_table_arn
}
output "telegram_xp_ledger_table_name" {
  value = module.telegram_xp_ledger.dynamodb_table_id
}

output "telegram_player_level_table_arn" {
  value = module.telegram_player_level.dynamodb_table_arn
}
output "telegram_player_level_table_name" {
  value = module.telegram_player_level.dynamodb_table_id
}

output "telegram_achievements_table_arn" {
  value = module.telegram_achievements.dynamodb_table_arn
}
output "telegram_achievements_table_name" {
  value = module.telegram_achievements.dynamodb_table_id
}
