# EnTutor (../../../entutor) — all five tables in one state, same consolidated
# layout as dynamodb/ttrpg_club/prod. All on-demand: traffic is one small burst
# a day per user, which is exactly the shape provisioned capacity handles badly.
#
# Content (words, exercises) is global and shared by every user; only cards and
# sessions are per-user. That's what keeps cost flat as users are added.

module "users" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name         = "entutor_prod_users"
  hash_key     = "userId"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    { name = "userId", type = "S" },
    { name = "active", type = "S" },
  ]

  # The hourly scheduler needs "every enrolled user" without scanning the whole
  # table. `active` is the string "true"/"false" because DynamoDB cannot index
  # a boolean attribute.
  global_secondary_indexes = [
    {
      name            = "active-index"
      hash_key        = "active"
      projection_type = "ALL"
    }
  ]

  tags = local.tags
}

module "words" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name         = "entutor_prod_words"
  hash_key     = "wordId"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    { name = "wordId", type = "S" },
    { name = "cefr", type = "S" },
    { name = "frequencyRank", type = "N" },
  ]

  # "Next unseen words at this level, most useful first" — a single Query in
  # frequency order rather than a scan-and-sort.
  global_secondary_indexes = [
    {
      name            = "cefr-rank-index"
      hash_key        = "cefr"
      range_key       = "frequencyRank"
      projection_type = "ALL"
    }
  ]

  tags = local.tags
}

module "cards" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name         = "entutor_prod_cards"
  hash_key     = "userId"
  range_key    = "wordId"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    { name = "userId", type = "S" },
    { name = "wordId", type = "S" },
    { name = "dueDate", type = "S" },
  ]

  # The query behind every session: this user's cards due on or before today.
  # An LSI (not a GSI) because it's always scoped to a single userId, and LSIs
  # give strongly consistent reads off the same partition.
  local_secondary_indexes = [
    {
      name            = "dueDate-index"
      range_key       = "dueDate"
      projection_type = "ALL"
    }
  ]

  tags = local.tags
}

module "exercises" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name         = "entutor_prod_exercises"
  hash_key     = "wordId"
  range_key    = "exerciseId"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    { name = "wordId", type = "S" },
    { name = "exerciseId", type = "S" },
  ]

  tags = local.tags
}

module "sessions" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name         = "entutor_prod_sessions"
  hash_key     = "sessionId"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    { name = "sessionId", type = "S" },
  ]

  # Sessions are scratch state for one day's seven taps. TTL means this table
  # never needs pruning.
  ttl_enabled        = true
  ttl_attribute_name = "expiresAt"

  tags = local.tags
}

locals {
  tags = {
    Terraform   = "true"
    Project     = "entutor"
    Environment = "production"
  }
}
