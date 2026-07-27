module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = var.function_name
  description   = "TTRPG club website API — signup, games, poll, comments, profiles, admin"
  handler       = "api.handler"
  runtime       = "nodejs24.x"
  timeout       = 15
  memory_size   = 256

  # Hard cost ceiling: no matter how much traffic hits the API, at most this many
  # invocations run at once. Paired with the API Gateway throttle below.
  reserved_concurrent_executions = var.reserved_concurrency

  attach_cloudwatch_logs_policy = true

  create_role = false
  lambda_role = aws_iam_role.lambda_role.arn

  # Built by `npm run build --workspace backend` (esbuild), which bundles everything
  # except @aws-sdk/* (already present in the Node.js 22.x Lambda runtime).
  source_path = [
    {
      path             = "../../../ttrpg_website2/backend/dist/api.js"
      pip_requirements = false
    }
  ]

  environment_variables = {
    TABLE_USERS             = data.terraform_remote_state.users_dynamodb.outputs.dynamodb_table_name
    TABLE_SIGNUP_REQUESTS   = data.terraform_remote_state.signup_requests_dynamodb.outputs.dynamodb_table_name
    TABLE_GAME_SYSTEMS      = data.terraform_remote_state.game_systems_dynamodb.outputs.dynamodb_table_name
    TABLE_GAMES             = data.terraform_remote_state.games_dynamodb.outputs.dynamodb_table_name
    TABLE_GAME_PARTICIPANTS = data.terraform_remote_state.game_participants_dynamodb.outputs.dynamodb_table_name
    TABLE_GAME_POLL_VOTES   = data.terraform_remote_state.game_poll_votes_dynamodb.outputs.dynamodb_table_name
    TABLE_GAME_COMMENTS     = data.terraform_remote_state.game_comments_dynamodb.outputs.dynamodb_table_name
    TABLE_SETTINGS          = data.terraform_remote_state.settings_dynamodb.outputs.dynamodb_table_name
    COGNITO_USER_POOL_ID    = data.terraform_remote_state.cognito.outputs.user_pool_id
    COGNITO_CLIENT_ID       = data.terraform_remote_state.cognito.outputs.web_client_id
    AVATAR_BUCKET           = data.terraform_remote_state.avatars_s3.outputs.bucket_name
    ALLOWED_ORIGIN          = var.cors_allowed_origin

    TABLE_TELEGRAM_RATING_VOTES = data.terraform_remote_state.telegram_rating_votes_dynamodb.outputs.dynamodb_table_name
    TELEGRAM_BOT_TOKEN_PARAM    = "/telegram/poll_bot/token"
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = var.function_name
  assume_role_policy = data.template_file.assume_role.rendered
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}Policy"
  path        = "/"
  description = "DynamoDB, Cognito and S3 access for the club API Lambda"
  policy      = data.template_file.policy.rendered
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "${var.function_name}_policy_attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_policy.arn
}
