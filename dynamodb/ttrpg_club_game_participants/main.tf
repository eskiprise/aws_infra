module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.1.0"

  name      = "ttrpg_club_game_participants"
  hash_key  = "userId"
  range_key = "gameId"

  attributes = var.attributes

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}
