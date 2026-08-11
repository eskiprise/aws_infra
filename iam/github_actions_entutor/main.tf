locals {
  account_id = data.aws_caller_identity.current.account_id

  # aws_infra/lambda/entutor_prod (Terraform) owns the functions themselves;
  # CI only ever pushes new code into them.
  function_name_pattern = "entutor-prod-*"
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "github-actions-entutor-deploy"

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
    Project   = "entutor"
  }
}

# Deliberately narrow, matching iam/github_actions_ttrpg_poll_bot: this role can
# replace the code in three named functions and nothing else. Terraform owns the
# infrastructure, so CI never needs IAM, API Gateway or DynamoDB permissions.
resource "aws_iam_role_policy" "deploy_permissions" {
  name = "entutor-deploy-permissions"
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
