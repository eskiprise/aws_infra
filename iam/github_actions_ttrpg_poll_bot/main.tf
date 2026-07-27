locals {
  account_id = data.aws_caller_identity.current.account_id
  service    = "telegram-poll-bot"

  # Serverless Framework's default naming — now only relevant for scoping the
  # (much narrower) code-update permissions below, since aws_infra/lambda/ttrpg_poll_bot
  # owns the actual infrastructure via Terraform.
  function_name_pattern = "${local.service}-*"
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "github-actions-ttrpg-poll-bot-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = data.aws_iam_openid_connect_provider.github_actions.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Terraform = "true"
    Project   = "ttrpg-club"
  }
}

# Narrow by design, matching ttrpg_website2's own CI role: aws_infra/lambda/ttrpg_poll_bot
# (Terraform) owns the Lambda functions, API Gateway, IAM role, and event source mappings
# — this role only ever needs to push new CODE into the 3 already-existing functions, the
# same "just update-function-code" shape the website's backend pipeline already uses.
# (Before the Serverless Framework -> Terraform migration, this role needed much broader
# CloudFormation/IAM/API-Gateway permissions to manage the whole stack from CI — see git
# history if that's ever needed again.)
resource "aws_iam_role_policy" "deploy_permissions" {
  name = "ttrpg-poll-bot-deploy-permissions"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UpdateLambdaCode"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunctionConfiguration",
        ]
        Resource = "arn:aws:lambda:${var.region}:${local.account_id}:function:${local.function_name_pattern}"
      },
    ]
  })
}
