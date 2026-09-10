module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = var.function_name
  description   = "TTRPG club website API (dev) — signup, games, poll, comments, profiles, admin"
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
    TABLE_USERS           = data.terraform_remote_state.dynamodb.outputs.users_table_name
    TABLE_SIGNUP_REQUESTS = data.terraform_remote_state.dynamodb.outputs.signup_requests_table_name
    TABLE_GAME_SYSTEMS    = data.terraform_remote_state.dynamodb.outputs.game_systems_table_name
    TABLE_GAME_COMMENTS   = data.terraform_remote_state.dynamodb.outputs.game_comments_table_name
    TABLE_SETTINGS        = data.terraform_remote_state.dynamodb.outputs.settings_table_name
    AVATAR_BUCKET         = data.terraform_remote_state.avatars_s3.outputs.bucket_name
    ALLOWED_ORIGINS       = join(",", var.cors_allowed_origins)

    TABLE_TELEGRAM_RATING_VOTES = data.terraform_remote_state.dynamodb.outputs.telegram_rating_votes_table_name
    TABLE_TELEGRAM_RATING_POLLS = data.terraform_remote_state.dynamodb.outputs.telegram_rating_polls_table_name
    TABLE_TELEGRAM_FEEDBACK     = data.terraform_remote_state.dynamodb.outputs.telegram_feedback_table_name
    TABLE_TELEGRAM_XP_LEDGER    = data.terraform_remote_state.dynamodb.outputs.telegram_xp_ledger_table_name
    TABLE_TELEGRAM_PLAYER_LEVEL = data.terraform_remote_state.dynamodb.outputs.telegram_player_level_table_name
    TABLE_TELEGRAM_ACHIEVEMENTS = data.terraform_remote_state.dynamodb.outputs.telegram_achievements_table_name
    TELEGRAM_BOT_TOKEN_PARAM    = "/ttrpg_club/dev/poll_bot/token"

    # Session JWTs are signed with a key derived from the bot token above, not a
    # separate secret — see backend/src/lib/session.ts.
    ADMIN_TELEGRAM_IDS = join(",", var.admin_telegram_ids)
    # Only set here (dev) — api.ts only registers POST /auth/dev-login when this is
    # non-empty, and it's deliberately left unset in prod so the route doesn't exist
    # there at all. Set a real value below before relying on it for local dev.
    DEV_LOGIN_SECRET = var.dev_login_secret
  }

  ignore_source_code_hash = true
}

resource "aws_iam_role" "lambda_role" {
  name               = var.function_name
  assume_role_policy = data.template_file.assume_role.rendered
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}Policy"
  path        = "/"
  description = "DynamoDB and S3 access for the club API Lambda"
  policy      = data.template_file.policy.rendered
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "${var.function_name}_policy_attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_policy.arn
}
