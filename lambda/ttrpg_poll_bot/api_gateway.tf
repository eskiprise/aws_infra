# HTTP API (v2) — matches what Serverless Framework's `httpApi:` events created (not the
# older REST API v1 shape aws_infra/lambda/bot uses), same resource kind as
# lambda/ttrpg_club_api's own API Gateway.

resource "aws_apigatewayv2_api" "bot" {
  # Serverless's actual naming is stage-first ("prod-telegram-poll-bot"), not the
  # service-stage order used elsewhere (confirmed against the real imported resource).
  name          = "prod-telegram-poll-bot"
  protocol_type = "HTTP"

  tags = {
    STAGE = "prod"
  }
}

resource "aws_apigatewayv2_integration" "webhook" {
  api_id                 = aws_apigatewayv2_api.bot.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.webhook.lambda_function_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "webhook_post" {
  api_id    = aws_apigatewayv2_api.bot.id
  route_key = "POST /webhook"
  target    = "integrations/${aws_apigatewayv2_integration.webhook.id}"
}

resource "aws_apigatewayv2_route" "webhook_get" {
  api_id    = aws_apigatewayv2_api.bot.id
  route_key = "GET /webhook"
  target    = "integrations/${aws_apigatewayv2_integration.webhook.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.bot.id
  name        = "$default"
  auto_deploy = true

  # Stage-wide default (custom.apiGatewayThrottling in the old serverless.yml).
  default_route_settings {
    throttling_rate_limit  = 20
    throttling_burst_limit = 10
  }

  # Per-route override — both /webhook routes had their own tighter throttle.
  route_settings {
    route_key              = aws_apigatewayv2_route.webhook_post.route_key
    throttling_rate_limit  = 10
    throttling_burst_limit = 5
  }

  route_settings {
    route_key              = aws_apigatewayv2_route.webhook_get.route_key
    throttling_rate_limit  = 10
    throttling_burst_limit = 5
  }

  route_settings {
    route_key              = aws_apigatewayv2_route.webhook_dev_post.route_key
    throttling_rate_limit  = 10
    throttling_burst_limit = 5
  }

  route_settings {
    route_key              = aws_apigatewayv2_route.webhook_dev_get.route_key
    throttling_rate_limit  = 10
    throttling_burst_limit = 5
  }

  tags = {
    STAGE = "prod"
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.webhook.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.bot.execution_arn}/*/*"
}

# --- Dev "stage" ---
#
# HTTP API v2 Lambda-proxy integrations are API-wide, not per-stage: a route always
# points at one fixed integration ARN, and (unlike REST API v1) that target can't be
# swapped per stage via stage variables. So a second aws_apigatewayv2_stage here would
# just be a redundant deployment serving the exact same routes/integrations — it
# couldn't route to the dev Lambda. Instead this reuses the one existing $default stage
# and adds a distinct path, /dev/webhook, wired to its own integration — same host,
# separate URL, separate Lambda, which is what actually matters for registering this as
# a second bot's webhook with Telegram.

resource "aws_apigatewayv2_integration" "webhook_dev" {
  api_id                 = aws_apigatewayv2_api.bot.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.webhook_dev.lambda_function_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "webhook_dev_post" {
  api_id    = aws_apigatewayv2_api.bot.id
  route_key = "POST /dev/webhook"
  target    = "integrations/${aws_apigatewayv2_integration.webhook_dev.id}"
}

resource "aws_apigatewayv2_route" "webhook_dev_get" {
  api_id    = aws_apigatewayv2_api.bot.id
  route_key = "GET /dev/webhook"
  target    = "integrations/${aws_apigatewayv2_integration.webhook_dev.id}"
}

resource "aws_lambda_permission" "apigw_dev" {
  statement_id  = "AllowAPIGatewayInvokeDev"
  action        = "lambda:InvokeFunction"
  function_name = module.webhook_dev.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.bot.execution_arn}/*/*"
}
