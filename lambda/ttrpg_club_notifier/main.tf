module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.9.0"

  function_name = var.function_name
  description   = "Posts new club signup requests to the club's Telegram bot"
  handler       = "notifier.handler"
  runtime       = "nodejs20.x"
  timeout       = 10
  memory_size   = 128

  attach_cloudwatch_logs_policy = true

  create_role = false
  lambda_role = aws_iam_role.lambda_role.arn

  source_path = [
    {
      path             = "../../../ttrpg_website/backend/dist/notifier.js"
      pip_requirements = false
    }
  ]

  environment_variables = {
    TELEGRAM_BOT_TOKEN_PARAM     = "/ttrpg-club/telegram-bot-token"
    TELEGRAM_ADMIN_CHAT_ID_PARAM = "/ttrpg-club/telegram-admin-chat-id"
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = var.function_name
  assume_role_policy = data.template_file.assume_role.rendered
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}Policy"
  path        = "/"
  description = "DynamoDB Streams read + SSM access for the Notifier Lambda"
  policy      = data.template_file.policy.rendered
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "${var.function_name}_policy_attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_event_source_mapping" "signup_requests_stream" {
  event_source_arn  = data.terraform_remote_state.signup_requests_dynamodb.outputs.dynamodb_table_stream_arn
  function_name     = module.lambda_function.lambda_function_name
  starting_position = "LATEST"
  batch_size        = 10
}
