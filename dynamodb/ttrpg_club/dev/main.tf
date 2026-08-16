# All ttrpg_club DynamoDB tables (dev environment) in one state, so a single
# `terraform apply` here manages every table instead of visiting 11 separate
# directories. Table names, keys, GSIs, and streams are unchanged from before this
# consolidation — this is purely a state reorganization, not a rebuild (the existing
# resources were moved in via `../migrate-dev-state.sh`, not recreated).

module "users" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_dev_users"
  hash_key = "userId"

  attributes = [
    { name = "userId", type = "S" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "signup_requests" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_dev_signup_requests"
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

  # The Notifier Lambda (ttrpg_poll_bot) subscribes to this stream to post new signup
  # requests to Telegram.
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

# Stream ARNs aren't deterministic (they carry a timestamp assigned when the stream is
# enabled, unlike a table ARN), so ttrpg_poll_bot's serverless.yml can't hardcode this —
# it reads it via `${ssm:...}` instead of a manual --param, and this value updates itself
# automatically on every apply (including if the table is ever destroyed and recreated).
resource "aws_ssm_parameter" "signup_requests_stream_arn" {
  name        = "/ttrpg_club/dev/signup_requests_stream_arn"
  type        = "String"
  value       = module.signup_requests.dynamodb_table_stream_arn
  description = "Stream ARN for ttrpg_club_signup_requests — consumed by ttrpg_poll_bot's notifySignup Lambda"

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "game_systems" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_dev_game_systems"
  hash_key = "systemId"

  attributes = [
    { name = "systemId", type = "S" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "games" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_dev_games"
  hash_key = "gameId"

  attributes = [
    { name = "gameId", type = "S" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "game_participants" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name      = "ttrpg_club_dev_game_participants"
  hash_key  = "userId"
  range_key = "gameId"

  attributes = [
    { name = "userId", type = "S" },
    { name = "gameId", type = "S" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "game_poll_votes" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name      = "ttrpg_club_dev_game_poll_votes"
  hash_key  = "gameId"
  range_key = "userId"

  attributes = [
    { name = "gameId", type = "S" },
    { name = "userId", type = "S" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "game_comments" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name      = "ttrpg_club_dev_game_comments"
  hash_key  = "gameId"
  range_key = "commentId"

  attributes = [
    { name = "gameId", type = "S" },
    { name = "commentId", type = "S" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "settings" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_dev_settings"
  hash_key = "pk"

  attributes = [
    { name = "pk", type = "S" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "telegram_rating_polls" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # Maps a Telegram poll_id -> the /rate question it was created for, so that
  # ttrpg_poll_bot can make sense of a later poll_answer webhook update (which only
  # carries poll_id + option_ids, not the original question). Each item also remembers
  # who ran the session (creatorUserId etc.) — the GSI below lets the club API answer
  # "My Games Conducted" without a table scan.
  name     = "ttrpg_club_dev_telegram_rating_polls"
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

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "telegram_rating_votes" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # Who rated what, from Telegram's poll_answer webhook updates — independent of whether
  # that Telegram user ever signed up on the club website. questionText is denormalized
  # onto each vote at write time (see telegram_rating_polls above) so reading a user's
  # history needs no second lookup.
  name      = "ttrpg_club_dev_telegram_rating_votes"
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

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "telegram_feedback" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # Detailed, mostly-anonymous feedback (four 1-10 ratings + optional free text) left via
  # the Mini App's feedback form, one item per submission for a given pollId. Kept
  # separate from telegram_rating_votes: that table is the quick 1-10 poll vote used for
  # stats math; this one is private qualitative feedback for the GM only.
  name      = "ttrpg_club_dev_telegram_feedback"
  hash_key  = "pollId"
  range_key = "feedbackId"

  attributes = [
    { name = "pollId", type = "S" },
    { name = "feedbackId", type = "S" }
  ]

  # The Notifier Lambda (ttrpg_poll_bot) subscribes to this stream to DM the GM.
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

resource "aws_ssm_parameter" "telegram_feedback_stream_arn" {
  name        = "/ttrpg_club/dev/telegram_feedback_stream_arn"
  type        = "String"
  value       = module.telegram_feedback.dynamodb_table_stream_arn
  description = "Stream ARN for ttrpg_club_telegram_feedback — consumed by ttrpg_poll_bot's notifyFeedback Lambda"

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "telegram_xp_ledger" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # Append-only audit trail of every XP award — the sole source of truth for "was this
  # already awarded" (conditional PutItem on sourceId), written only by ttrpg_poll_bot.
  # Never deleted, so retracting+revoting a poll answer can never re-earn XP.
  name      = "ttrpg_club_dev_telegram_xp_ledger"
  hash_key  = "telegramUserId"
  range_key = "sourceId"

  attributes = [
    { name = "telegramUserId", type = "N" },
    { name = "sourceId", type = "S" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "telegram_player_level" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # One row per player: current level/XP plus lifetime gamesPlayed/feedbackGiven
  # counters (used for achievement tiers). Written only by ttrpg_poll_bot; read by the
  # website backend for the Mini App's stats/achievements pages.
  name     = "ttrpg_club_dev_telegram_player_level"
  hash_key = "telegramUserId"

  attributes = [
    { name = "telegramUserId", type = "N" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

module "telegram_achievements" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # One-time badges, no XP — a row's existence is the unlock (conditional PutItem on
  # achievementId). Written only by ttrpg_poll_bot; read by the website backend.
  name      = "ttrpg_club_dev_telegram_achievements"
  hash_key  = "telegramUserId"
  range_key = "achievementId"

  attributes = [
    { name = "telegramUserId", type = "N" },
    { name = "achievementId", type = "S" }
  ]

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}
