# Prod environment for the ttrpg_club DynamoDB tables — brand new, empty, and
# independent of dev (same shapes/keys/GSIs/streams as dev, just prefixed table names
# since dev and prod share one AWS account+region and table names must be unique).
# Nothing reads from these yet: there's no prod Lambda/API or website deployment —
# these tables sit ready for whenever that's built.

module "users" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_prod_users"
  hash_key = "userId"

  attributes = [
    { name = "userId", type = "S" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "signup_requests" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_prod_signup_requests"
  hash_key = "requestId"

  attributes = [
    { name = "requestId", type = "S" },
    { name = "status", type = "S" }
  ]

  global_secondary_indexes = [
    {
      name            = "status-index"
      hash_key        = "status"
      projection_type = "ALL"
    }
  ]

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

resource "aws_ssm_parameter" "signup_requests_stream_arn" {
  name        = "/ttrpg_club/prod/signup_requests_stream_arn"
  type        = "String"
  value       = module.signup_requests.dynamodb_table_stream_arn
  description = "Stream ARN for ttrpg_club_prod_signup_requests — for a future prod notifySignup Lambda"

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "game_systems" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_prod_game_systems"
  hash_key = "systemId"

  attributes = [
    { name = "systemId", type = "S" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "games" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_prod_games"
  hash_key = "gameId"

  attributes = [
    { name = "gameId", type = "S" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "game_participants" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name      = "ttrpg_club_prod_game_participants"
  hash_key  = "userId"
  range_key = "gameId"

  attributes = [
    { name = "userId", type = "S" },
    { name = "gameId", type = "S" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "game_poll_votes" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name      = "ttrpg_club_prod_game_poll_votes"
  hash_key  = "gameId"
  range_key = "userId"

  attributes = [
    { name = "gameId", type = "S" },
    { name = "userId", type = "S" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "game_comments" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name      = "ttrpg_club_prod_game_comments"
  hash_key  = "gameId"
  range_key = "commentId"

  attributes = [
    { name = "gameId", type = "S" },
    { name = "commentId", type = "S" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "settings" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_prod_settings"
  hash_key = "pk"

  attributes = [
    { name = "pk", type = "S" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "telegram_rating_polls" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_prod_telegram_rating_polls"
  hash_key = "pollId"

  attributes = [
    { name = "pollId", type = "S" },
    { name = "creatorUserId", type = "N" }
  ]

  global_secondary_indexes = [
    {
      name            = "creatorUserId-index"
      hash_key        = "creatorUserId"
      projection_type = "ALL"
    }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "telegram_rating_votes" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name      = "ttrpg_club_prod_telegram_rating_votes"
  hash_key  = "pollId"
  range_key = "telegramUserId"

  attributes = [
    { name = "pollId", type = "S" },
    { name = "telegramUserId", type = "N" }
  ]

  global_secondary_indexes = [
    {
      name            = "telegramUserId-index"
      hash_key        = "telegramUserId"
      projection_type = "ALL"
    }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "telegram_feedback" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name      = "ttrpg_club_prod_telegram_feedback"
  hash_key  = "pollId"
  range_key = "feedbackId"

  attributes = [
    { name = "pollId", type = "S" },
    { name = "feedbackId", type = "S" }
  ]

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

resource "aws_ssm_parameter" "telegram_feedback_stream_arn" {
  name        = "/ttrpg_club/prod/telegram_feedback_stream_arn"
  type        = "String"
  value       = module.telegram_feedback.dynamodb_table_stream_arn
  description = "Stream ARN for ttrpg_club_prod_telegram_feedback — for a future prod notifyFeedback Lambda"

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "telegram_xp_ledger" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # Append-only audit trail of every XP award — the sole source of truth for "was this
  # already awarded" (conditional PutItem on sourceId), written only by ttrpg_poll_bot.
  # Never deleted, so retracting+revoting a poll answer can never re-earn XP.
  name      = "ttrpg_club_prod_telegram_xp_ledger"
  hash_key  = "telegramUserId"
  range_key = "sourceId"

  attributes = [
    { name = "telegramUserId", type = "N" },
    { name = "sourceId", type = "S" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "telegram_player_level" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # One row per player: current level/XP plus lifetime gamesPlayed/feedbackGiven
  # counters (used for achievement tiers). Written only by ttrpg_poll_bot; read by the
  # website backend for the Mini App's stats/achievements pages.
  name     = "ttrpg_club_prod_telegram_player_level"
  hash_key = "telegramUserId"

  attributes = [
    { name = "telegramUserId", type = "N" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}

module "telegram_achievements" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # One-time badges, no XP — a row's existence is the unlock (conditional PutItem on
  # achievementId). Written only by ttrpg_poll_bot; read by the website backend.
  name      = "ttrpg_club_prod_telegram_achievements"
  hash_key  = "telegramUserId"
  range_key = "achievementId"

  attributes = [
    { name = "telegramUserId", type = "N" },
    { name = "achievementId", type = "S" }
  ]

  point_in_time_recovery_enabled = true

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "production"
  }
}
