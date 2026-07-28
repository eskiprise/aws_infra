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
