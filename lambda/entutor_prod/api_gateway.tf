# HTTP API (v2), same shape as lambda/ttrpg_poll_bot_prod/api_gateway.tf.
#
# Only POST /webhook is routed. The endpoint is public by necessity — Telegram
# has to reach it — so the Lambda verifies the X-Telegram-Bot-Api-Secret-Token
# header on every request and returns 403 otherwise.

resource "aws_apigatewayv2_api" "bot" {
  name          = "prod-entutor"
  protocol_type = "HTTP"

  tags = local.tags
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

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.bot.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = 20
    throttling_burst_limit = 10
  }

  # A real user generates at most a handful of taps a second; this bounds what
  # an unauthenticated flood can cost before the 403 check even runs.
  route_settings {
    route_key              = aws_apigatewayv2_route.webhook_post.route_key
    throttling_rate_limit  = 10
    throttling_burst_limit = 5
  }

  tags = local.tags
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.webhook.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.bot.execution_arn}/*/*"
}
