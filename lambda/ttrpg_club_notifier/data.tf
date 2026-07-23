data "aws_caller_identity" "current" {}

data "terraform_remote_state" "signup_requests_dynamodb" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dynamodb/ttrpg_club_signup_requests/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "ssm_ttrpg_club" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "ssm/ttrpg_club/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "template_file" "assume_role" {
  template = file("${path.module}/templates/assume_role.tpl")
}

data "template_file" "policy" {
  template = file("${path.module}/templates/policy.tpl")
  vars = {
    account_id          = data.aws_caller_identity.current.account_id
    region              = var.region
    function_name       = var.function_name
    stream_arn          = data.terraform_remote_state.signup_requests_dynamodb.outputs.dynamodb_table_stream_arn
    bot_token_param_arn = data.terraform_remote_state.ssm_ttrpg_club.outputs.parameters_arn["/ttrpg-club/telegram-bot-token"]
    chat_id_param_arn   = data.terraform_remote_state.ssm_ttrpg_club.outputs.parameters_arn["/ttrpg-club/telegram-admin-chat-id"]
  }
}
