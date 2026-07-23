data "aws_caller_identity" "current" {}

data "terraform_remote_state" "users_dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club_users/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "signup_requests_dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club_signup_requests/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "game_systems_dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club_game_systems/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "games_dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club_games/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "game_participants_dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club_game_participants/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "game_poll_votes_dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club_game_poll_votes/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "game_comments_dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club_game_comments/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "settings_dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club_settings/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "cognito" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "cognito/ttrpg_club/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "avatars_s3" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "s3/ttrpg_club_avatars/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "template_file" "assume_role" {
  template = file("${path.module}/templates/assume_role.tpl")
}

data "template_file" "policy" {
  template = file("${path.module}/templates/policy.tpl")
  vars = {
    account_id              = data.aws_caller_identity.current.account_id
    region                  = var.region
    function_name           = var.function_name
    users_table             = data.terraform_remote_state.users_dynamodb.outputs.dynamodb_table_arn
    signup_requests_table   = data.terraform_remote_state.signup_requests_dynamodb.outputs.dynamodb_table_arn
    game_systems_table      = data.terraform_remote_state.game_systems_dynamodb.outputs.dynamodb_table_arn
    games_table             = data.terraform_remote_state.games_dynamodb.outputs.dynamodb_table_arn
    game_participants_table = data.terraform_remote_state.game_participants_dynamodb.outputs.dynamodb_table_arn
    game_poll_votes_table   = data.terraform_remote_state.game_poll_votes_dynamodb.outputs.dynamodb_table_arn
    game_comments_table     = data.terraform_remote_state.game_comments_dynamodb.outputs.dynamodb_table_arn
    settings_table          = data.terraform_remote_state.settings_dynamodb.outputs.dynamodb_table_arn
    user_pool_arn           = data.terraform_remote_state.cognito.outputs.user_pool_arn
    avatars_bucket_arn      = data.terraform_remote_state.avatars_s3.outputs.bucket_arn
  }
}
