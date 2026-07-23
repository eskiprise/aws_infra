module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name     = "ttrpg_club_signup_requests"
  hash_key = "requestId"

  attributes = var.attributes

  global_secondary_indexes = [
    {
      name            = "status-index"
      hash_key        = "status"
      projection_type = "ALL"
    }
  ]

  # The Notifier Lambda subscribes to this stream to post new signup requests to Telegram.
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}
