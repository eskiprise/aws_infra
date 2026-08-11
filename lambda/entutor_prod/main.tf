# EnTutor (../../../entutor) — three functions behind one shared IAM role,
# following the shape of lambda/ttrpg_poll_bot_prod.
#
#   webhook    HTTP API POST /webhook   commands + inline-button answers
#   scheduler  EventBridge, hourly      queue users whose local time is 14:00
#   sender     SQS                      build and send one user's session
#
# No Anthropic API key anywhere: exercise content is generated offline and
# seeded into DynamoDB, so nothing here calls an LLM at runtime.

locals {
  table_names = {
    users     = "entutor_prod_users"
    words     = "entutor_prod_words"
    cards     = "entutor_prod_cards"
    exercises = "entutor_prod_exercises"
    sessions  = "entutor_prod_sessions"
  }

  table_arns = [
    for name in values(local.table_names) :
    "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${name}"
  ]

  # Queries hit indexes, which are separate resources in IAM.
  table_index_arns = [for arn in local.table_arns : "${arn}/index/*"]

  environment_variables = {
    TELEGRAM_TOKEN_SSM_PARAMETER = "/entutor/prod/bot/token"
    WEBHOOK_SECRET_SSM_PARAMETER = "/entutor/prod/bot/webhook_secret"
    USERS_TABLE                  = local.table_names.users
    WORDS_TABLE                  = local.table_names.words
    CARDS_TABLE                  = local.table_names.cards
    EXERCISES_TABLE              = local.table_names.exercises
    SESSIONS_TABLE               = local.table_names.sessions
    SEND_QUEUE_URL               = aws_sqs_queue.daily_send.url
    ADMIN_CHAT_ID                = var.admin_chat_id
    SEND_HOUR                    = tostring(var.send_hour)
    DEFAULT_TIMEZONE             = var.default_timezone
    LOW_POOL_THRESHOLD           = tostring(var.low_pool_threshold)
  }

  tags = {
    Terraform = "true"
    Project   = "entutor"
    STAGE     = "prod"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "entutor-prod-lambdaRole"

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

  tags = local.tags
}

resource "aws_iam_role_policy" "bot_permissions" {
  name = "entutor-prod-lambda"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:CreateLogGroup"]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/entutor-prod*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:PutLogEvents"]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/entutor-prod*:*:*"
        ]
      },
      {
        # Scoped to this bot's parameters only, not the whole SSM tree.
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/entutor/prod/bot/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:BatchGetItem",
        ]
        Resource = concat(local.table_arns, local.table_index_arns)
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = [aws_sqs_queue.daily_send.arn]
      },
      {
        # Required by the event source mapping on `sender`.
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = [aws_sqs_queue.daily_send.arn]
      },
    ]
  })
}

module "webhook" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "entutor-prod-webhook"
  description   = "EnTutor — receives Telegram updates, handles commands and answers"
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.14"
  timeout       = 30
  memory_size   = 512

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role.arn
  attach_cloudwatch_logs_policy = false

  # Built by `./build.sh`. Only used for the INITIAL apply — every later code
  # change ships via CI's `aws lambda update-function-code`. All three modules
  # share this path; `hash_extra` keeps their output zip names distinct so they
  # don't race to build the same file.
  source_path = [
    {
      path             = "../../../entutor/build"
      pip_requirements = false
    }
  ]
  hash_extra = "webhook"

  environment_variables = local.environment_variables
  tags                  = local.tags
}

module "scheduler" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "entutor-prod-scheduler"
  description   = "EnTutor — hourly sweep, queues users whose local time is 14:00"
  handler       = "lambda_handler.scheduler"
  runtime       = "python3.14"
  timeout       = 60
  memory_size   = 256

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../entutor/build"
      pip_requirements = false
    }
  ]
  hash_extra = "scheduler"

  environment_variables = local.environment_variables
  tags                  = local.tags
}

module "sender" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "entutor-prod-sender"
  description   = "EnTutor — builds and sends one user's daily session"
  handler       = "lambda_handler.sender"
  runtime       = "python3.14"
  timeout       = 60
  memory_size   = 512

  # Telegram allows roughly 30 messages/second globally. Capping concurrency
  # here is what keeps a large fan-out from tripping 429s en masse.
  reserved_concurrent_executions = var.sender_concurrency

  create_role                   = false
  lambda_role                   = aws_iam_role.lambda_role.arn
  attach_cloudwatch_logs_policy = false

  source_path = [
    {
      path             = "../../../entutor/build"
      pip_requirements = false
    }
  ]
  hash_extra = "sender"

  environment_variables = local.environment_variables
  tags                  = local.tags
}

resource "aws_ssm_parameter" "entutor_prod" {
  for_each    = var.entutor_prod_params
  name        = each.key
  description = each.value
  type        = "SecureString"
  value       = "replace_me!"

  lifecycle {
    ignore_changes = [value]
  }

  tags = local.tags
}
