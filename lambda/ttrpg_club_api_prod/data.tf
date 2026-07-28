data "aws_caller_identity" "current" {}

# Prod counterpart to ../ttrpg_club_api — reads dynamodb/ttrpg_club/prod (the empty,
# isolated environment) instead of .../dev, plus this module's own prod cognito/avatars
# remote states.
data "terraform_remote_state" "dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club/prod/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "cognito" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "cognito/ttrpg_club_prod/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "avatars_s3" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "s3/ttrpg_club_avatars_prod/terraform.tfstate"
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
    users_table             = data.terraform_remote_state.dynamodb.outputs.users_table_arn
    signup_requests_table   = data.terraform_remote_state.dynamodb.outputs.signup_requests_table_arn
    game_systems_table      = data.terraform_remote_state.dynamodb.outputs.game_systems_table_arn
    games_table             = data.terraform_remote_state.dynamodb.outputs.games_table_arn
    game_participants_table = data.terraform_remote_state.dynamodb.outputs.game_participants_table_arn
    game_poll_votes_table   = data.terraform_remote_state.dynamodb.outputs.game_poll_votes_table_arn
    game_comments_table     = data.terraform_remote_state.dynamodb.outputs.game_comments_table_arn
    settings_table          = data.terraform_remote_state.dynamodb.outputs.settings_table_arn
    user_pool_arn           = data.terraform_remote_state.cognito.outputs.user_pool_arn
    avatars_bucket_arn      = data.terraform_remote_state.avatars_s3.outputs.bucket_arn

    telegram_rating_votes_table = data.terraform_remote_state.dynamodb.outputs.telegram_rating_votes_table_arn
    telegram_rating_polls_table = data.terraform_remote_state.dynamodb.outputs.telegram_rating_polls_table_arn
    telegram_feedback_table     = data.terraform_remote_state.dynamodb.outputs.telegram_feedback_table_arn
    # Not managed by any Terraform state (created ad hoc alongside ttrpg_poll_bot) —
    # constructed directly rather than via a remote state lookup. Same token as dev: this
    # param verifies Telegram initData signatures, unrelated to which table set is read.
    telegram_bot_token_param_arn = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/telegram/poll_bot/token"
  }
}
