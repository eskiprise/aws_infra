# Own dedicated HTTP API (v2), separate from ../ttrpg_poll_bot_prod's — the two used to
# share one API Gateway via a /dev/webhook path (necessary back when HTTP API v2's
# Lambda-proxy integration couldn't route differently per stage), but a real separate
# module gets a real separate API instead, with a plain /webhook path of its own.

resource "aws_apigatewayv2_api" "bot" {
  name          = "dev-telegram-poll-bot"
  protocol_type = "HTTP"

  tags = {
    STAGE = "dev"
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

  default_route_settings {
    throttling_rate_limit  = 20
    throttling_burst_limit = 10
  }

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
    STAGE = "dev"
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.webhook.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.bot.execution_arn}/*/*"
}
