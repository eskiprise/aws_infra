module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # Who rated what, from Telegram's poll_answer webhook updates — independent of
  # whether that Telegram user ever signed up on the club website. questionText
  # is denormalized onto each vote at write time (see ttrpg_club_telegram_rating_polls)
  # so reading a user's history needs no second lookup.
  name      = "ttrpg_club_telegram_rating_votes"
  hash_key  = "pollId"
  range_key = "telegramUserId"

  attributes = var.attributes

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
