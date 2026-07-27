module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  # Maps a Telegram poll_id -> the /rate question it was created for, so that
  # ttrpg_poll_bot can make sense of a later poll_answer webhook update (which
  # only carries poll_id + option_ids, not the original question).
  name     = "ttrpg_club_telegram_rating_polls"
  hash_key = "pollId"

  attributes = var.attributes

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}
