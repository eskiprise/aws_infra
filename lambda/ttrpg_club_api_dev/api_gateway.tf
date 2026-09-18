# HTTP API (v2) rather than a REST API — cheaper per-request and simpler to wire many
# routes to one Lambda than the per-function REST API pattern used by lambda/bot.
# Auth is NOT done via an API Gateway JWT authorizer: several public routes (e.g. the
# Game Log) need to behave differently for logged-in vs anonymous callers, which HTTP
# API's authorizer can't express as "optional". So every route below is authorization
# type NONE, and the Lambda verifies the Cognito ID token itself when a route needs it.

resource "aws_apigatewayv2_api" "ttrpg_club" {
  name          = "ttrpg-club-api-dev"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors_allowed_origins
    allow_methods = ["GET", "POST", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["Authorization", "Content-Type"]
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.ttrpg_club.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_function.lambda_function_invoke_arn
  payload_format_version = "2.0"
}

locals {
  # Must match the `routes` keys in ttrpg_website2/backend/src/handlers/api.ts exactly —
  # API Gateway's route_key IS what the Lambda sees as event.routeKey.
  route_keys = toset([
    "GET /health",
    "POST /signup",
    "POST /auth/telegram",
    # Registered unconditionally here (dev only — absent from the prod module's own
    # route_keys entirely) — the Lambda's own routes table additionally gates on
    # DEV_LOGIN_SECRET being set, but even without it the request should reach the
    # Lambda and get a clean 404 from there rather than one from API Gateway.
    "POST /auth/dev-login",
    "GET /game-systems",
    "GET /game-systems/{systemId}",
    "POST /admin/game-systems",
    "POST /admin/game-systems/image-upload-url",
    "PATCH /admin/game-systems/{systemId}",
    "DELETE /admin/game-systems/{systemId}",
    "GET /media",
    "POST /admin/media/upload-url",
    "POST /admin/media",
    "PATCH /admin/media/{mediaId}",
    "DELETE /admin/media/{mediaId}",
    "GET /game-masters",
    "GET /game-masters/{userId}",
    "GET /game-log",
    "GET /game-log/{pollId}",
    "GET /game-log/{pollId}/comments",
    "POST /game-log/{pollId}/comments",
    "DELETE /admin/game-log/{pollId}/comments/{commentId}",
    "GET /members",
    "GET /statistics",
    "POST /telegram/stats",
    "POST /telegram/polls",
    "POST /telegram/feedback",
    "POST /telegram/feedback/eligibility",
    "POST /telegram/games/played",
    "POST /telegram/games/conducted",
    "POST /telegram/games/all",
    "POST /telegram/games/{pollId}/voters",
    "POST /telegram/leaderboard",
    "POST /telegram/achievements",
    "GET /me",
    "PATCH /me/profile",
    "POST /me/avatar-upload-url",
    "GET /admin/signup-requests",
    "POST /admin/signup-requests/{requestId}/acknowledge",
    "PATCH /admin/settings/anonymize-toggle",
    "GET /admin/users",
    "PATCH /admin/users/{userId}/roles",
  ])
}

resource "aws_apigatewayv2_route" "routes" {
  for_each  = local.route_keys
  api_id    = aws_apigatewayv2_api.ttrpg_club.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.ttrpg_club.id
  name        = "$default"
  auto_deploy = true

  # Applies to every route that doesn't set its own route_settings override below —
  # rejects excess requests with 429 before they ever reach the Lambda, so a request
  # flood can't run up Lambda/DynamoDB costs. Account-wide, not per-IP (HTTP API has
  # no built-in per-IP throttling; that needs AWS WAF, which costs extra — worth
  # adding later if a single abusive IP becomes a real problem).
  default_route_settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ttrpg_club.execution_arn}/*/*"
}
