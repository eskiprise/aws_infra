locals {
  prod_environment_variables = {
    TELEGRAM_TOKEN_SSM_PARAMETER = "/ttrpg_club/prod/poll_bot/token"
    ADMIN_CHAT_ID                = var.admin_chat_id
    TELEGRAM_RATING_POLLS_TABLE  = "ttrpg_club_prod_telegram_rating_polls"
    TELEGRAM_RATING_VOTES_TABLE  = "ttrpg_club_prod_telegram_rating_votes"
    MINI_APP_DEEP_LINK           = var.mini_app_deep_link
  }

  dev_admin_chat_id = var.dev_admin_chat_id != "" ? var.dev_admin_chat_id : var.admin_chat_id

  # Isolated dev/test stage: its own bot token, its own admin chat (optional), and the
  # dynamodb/ttrpg_club/prod tables (currently empty — nothing else reads/writes them),
  # so testing here can never touch real member/club data.
  dev_environment_variables = {
    TELEGRAM_TOKEN_SSM_PARAMETER = "/ttrpg_club/dev/poll_bot/token"
    ADMIN_CHAT_ID                = local.dev_admin_chat_id
    TELEGRAM_RATING_POLLS_TABLE  = "ttrpg_club_dev_telegram_rating_polls"
    TELEGRAM_RATING_VOTES_TABLE  = "ttrpg_club_dev_telegram_rating_votes"
    MINI_APP_DEEP_LINK           = var.mini_app_deep_link_dev
  }
}

# -------------------------------
#               PROD
# -------------------------------

# One shared IAM role for all 3 functions, matching what Serverless Framework's default
# (no per-function `role:` override in the old serverless.yml) already created — this is
# the exact shape being imported, not a redesign, so `terraform import` has something
# real to match against.

resource "aws_iam_role" "lambda_role" {
  name = "telegram-poll-bot-prod-eu-west-2-lambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    STAGE = "prod"
  }
}

# Ported 1:1 from serverless.yml's provider.iam.role.statements, PLUS the basic logging
# statements Serverless Framework always bundles into this same single inline policy by
# default (confirmed against the real imported resource — there is no separate
# AWSLambdaBasicExecutionRole attachment at all, everything lives here). Import script's
# discovery step confirms the exact inline policy name before importing this resource,
# since it's not something Terraform gets to choose after the fact.
resource "aws_iam_role_policy" "bot_permissions" {
  name = "telegram-poll-bot-prod-lambda"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:CreateLogGroup"]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/telegram-poll-bot-prod*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:PutLogEvents"]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/telegram-poll-bot-prod*:*:*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/ttrpg_club/prod/poll_bot/token"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams",
        ]
        Resource = [
          data.aws_ssm_parameter.signup_requests_stream_arn_prod.value,
          data.aws_ssm_parameter.telegram_feedback_stream_arn_prod.value,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
        ]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/ttrpg_club_prod_telegram_rating_polls"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/ttrpg_club_prod_telegram_rating_votes"
      },
    ]
  })
}


module "webhook" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "telegram-poll-bot-prod-webhook"
  description   = "Telegram Poll Bot — receives the webhook, handles commands and poll answers"
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role.arn
  attach_cloudwatch_logs_policy = false

  # Built by `./build.sh` — the Python equivalent of the website's esbuild step. Only
  # used for the INITIAL apply/import — every later code change ships via CI's
  # `aws lambda update-function-code`. All 3 modules share this same source_path
  # (identical code) — hash_extra below is what keeps their internally-computed output
  # zip filenames distinct, so they don't race to build/rename the same file.
  source_path = [
    {
      path             = "../../../ttrpg_poll_bot/build"
      pip_requirements = false
    }
  ]
  hash_extra = "webhook"

  environment_variables = local.prod_environment_variables
}

module "notify_signup" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "telegram-poll-bot-prod-notifySignup"
  description   = "Telegram Poll Bot — DMs the admin chat about new club signup requests"
  handler       = "lambda_handler.notify_new_signup"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../ttrpg_poll_bot/build"
      pip_requirements = false
    }
  ]
  hash_extra = "notify_signup"

  environment_variables = local.prod_environment_variables
}

module "notify_feedback" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "telegram-poll-bot-prod-notifyFeedback"
  description   = "Telegram Poll Bot — DMs the GM when new session feedback is submitted"
  handler       = "lambda_handler.notify_new_feedback"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../ttrpg_poll_bot/build"
      pip_requirements = false
    }
  ]
  hash_extra = "notify_feedback"

  environment_variables = local.prod_environment_variables
}

resource "aws_lambda_event_source_mapping" "notify_signup" {
  event_source_arn  = data.aws_ssm_parameter.signup_requests_stream_arn_prod.value
  function_name     = module.notify_signup.lambda_function_arn
  starting_position = "LATEST"
  batch_size        = 10

  tags = {
    STAGE = "prod"
  }
}

resource "aws_lambda_event_source_mapping" "notify_feedback" {
  event_source_arn  = data.aws_ssm_parameter.telegram_feedback_stream_arn_prod.value
  function_name     = module.notify_feedback.lambda_function_arn
  starting_position = "LATEST"
  batch_size        = 10

  tags = {
    STAGE = "prod"
  }
}

resource "aws_ssm_parameter" "ttrpg_prod" {
  for_each    = var.ttrpg_prod_params
  name        = each.key
  description = each.value
  type        = "SecureString"
  value       = "replace_me!"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}



# -------------------------------
#               DEV
# -------------------------------

# Separate role from the prod one above — scoped to the dev token param and the prod
# (empty, isolated) DynamoDB tables/streams, so a bug in the dev/test bot can't reach
# anything the real bot uses.
resource "aws_iam_role" "lambda_role_dev" {
  name = "telegram-poll-bot-dev-eu-west-2-lambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    STAGE = "dev"
  }
}

resource "aws_iam_role_policy" "bot_permissions_dev" {
  name = "telegram-poll-bot-dev-lambda"
  role = aws_iam_role.lambda_role_dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:CreateLogGroup"]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/telegram-poll-bot-dev*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:PutLogEvents"]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/telegram-poll-bot-dev*:*:*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/ttrpg_club/dev/poll_bot/token"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams",
        ]
        Resource = [
          data.aws_ssm_parameter.signup_requests_stream_arn_dev.value,
          data.aws_ssm_parameter.telegram_feedback_stream_arn_dev.value,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
        ]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/ttrpg_club_dev_telegram_rating_polls"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/ttrpg_club_dev_telegram_rating_votes"
      },
    ]
  })
}

# --- Dev stage: same 3 functions, isolated role/tables/token, reached via the
# /dev/webhook route in api_gateway.tf instead of a second API Gateway. ---

module "webhook_dev" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "telegram-poll-bot-dev-webhook"
  description   = "Telegram Poll Bot (dev) — receives the webhook, handles commands and poll answers"
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role_dev.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../ttrpg_poll_bot/build"
      pip_requirements = false
    }
  ]
  hash_extra = "webhook_dev"

  environment_variables = local.dev_environment_variables
}

module "notify_signup_dev" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "telegram-poll-bot-dev-notifySignup"
  description   = "Telegram Poll Bot (dev) — DMs the admin chat about new club signup requests"
  handler       = "lambda_handler.notify_new_signup"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role_dev.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../ttrpg_poll_bot/build"
      pip_requirements = false
    }
  ]
  hash_extra = "notify_signup_dev"

  environment_variables = local.dev_environment_variables
}

module "notify_feedback_dev" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "telegram-poll-bot-dev-notifyFeedback"
  description   = "Telegram Poll Bot (dev) — DMs the GM when new session feedback is submitted"
  handler       = "lambda_handler.notify_new_feedback"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role_dev.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../ttrpg_poll_bot/build"
      pip_requirements = false
    }
  ]
  hash_extra = "notify_feedback_dev"

  environment_variables = local.dev_environment_variables
}

resource "aws_lambda_event_source_mapping" "notify_signup_dev" {
  event_source_arn  = data.aws_ssm_parameter.signup_requests_stream_arn_prod.value
  function_name     = module.notify_signup_dev.lambda_function_arn
  starting_position = "LATEST"
  batch_size        = 10

  tags = {
    STAGE = "dev"
  }
}

resource "aws_lambda_event_source_mapping" "notify_feedback_dev" {
  event_source_arn  = data.aws_ssm_parameter.telegram_feedback_stream_arn_prod.value
  function_name     = module.notify_feedback_dev.lambda_function_arn
  starting_position = "LATEST"
  batch_size        = 10

  tags = {
    STAGE = "dev"
  }
}

resource "aws_ssm_parameter" "ttrpg_dev" {
  for_each    = var.ttrpg_dev_params
  name        = each.key
  description = each.value
  type        = "SecureString"
  value       = "replace_me!"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}


