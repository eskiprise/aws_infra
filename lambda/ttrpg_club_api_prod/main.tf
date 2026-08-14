module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = var.function_name
  description   = "TTRPG club website API (prod) — signup, games, poll, comments, profiles, admin"
  handler       = "api.handler"
  runtime       = "nodejs24.x"
  timeout       = 15
  memory_size   = 256

  # Hard cost ceiling: no matter how much traffic hits the API, at most this many
  # invocations run at once. Paired with the API Gateway throttle below.
  reserved_concurrent_executions = var.reserved_concurrency

  attach_cloudwatch_logs_policy = true

  # Structured JSON logs (rather than plain text) so every log line reliably carries a
  # "level" field — monitoring/ttrpg_club_prod_alerts filters on level=ERROR to forward
  # errors to Telegram. Without this, console.error() output has no dependable machine-
  # parseable marker to filter on.
  logging_log_format = "JSON"

  create_role = false
  lambda_role = aws_iam_role.lambda_role.arn

  # Built by `npm run build --workspace backend` (esbuild), which bundles everything
  # except @aws-sdk/* (already present in the Node.js runtime). Same code as dev — CI
  # pushes it to both functions via `aws lambda update-function-code`.
  source_path = [
    {
      path             = "../../../ttrpg_website2/backend/dist/api.js"
      pip_requirements = false
    }
  ]

  environment_variables = {
    TABLE_USERS             = data.terraform_remote_state.dynamodb.outputs.users_table_name
    TABLE_SIGNUP_REQUESTS   = data.terraform_remote_state.dynamodb.outputs.signup_requests_table_name
    TABLE_GAME_SYSTEMS      = data.terraform_remote_state.dynamodb.outputs.game_systems_table_name
    TABLE_GAMES             = data.terraform_remote_state.dynamodb.outputs.games_table_name
    TABLE_GAME_PARTICIPANTS = data.terraform_remote_state.dynamodb.outputs.game_participants_table_name
    TABLE_GAME_POLL_VOTES   = data.terraform_remote_state.dynamodb.outputs.game_poll_votes_table_name
    TABLE_GAME_COMMENTS     = data.terraform_remote_state.dynamodb.outputs.game_comments_table_name
    TABLE_SETTINGS          = data.terraform_remote_state.dynamodb.outputs.settings_table_name
    COGNITO_USER_POOL_ID    = data.terraform_remote_state.cognito.outputs.user_pool_id
    COGNITO_CLIENT_ID       = data.terraform_remote_state.cognito.outputs.web_client_id
    AVATAR_BUCKET           = data.terraform_remote_state.avatars_s3.outputs.bucket_name
    ALLOWED_ORIGIN          = var.cors_allowed_origin

    TABLE_TELEGRAM_RATING_VOTES = data.terraform_remote_state.dynamodb.outputs.telegram_rating_votes_table_name
    TABLE_TELEGRAM_RATING_POLLS = data.terraform_remote_state.dynamodb.outputs.telegram_rating_polls_table_name
    TABLE_TELEGRAM_FEEDBACK     = data.terraform_remote_state.dynamodb.outputs.telegram_feedback_table_name
    TELEGRAM_BOT_TOKEN_PARAM    = "/ttrpg_club/prod/poll_bot/token"
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = var.function_name
  assume_role_policy = data.template_file.assume_role.rendered
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}Policy"
  path        = "/"
  description = "DynamoDB, Cognito and S3 access for the club API Lambda (prod)"
  policy      = data.template_file.policy.rendered
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "${var.function_name}_policy_attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_policy.arn
}
