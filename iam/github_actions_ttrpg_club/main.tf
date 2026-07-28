locals {
  lambda_function_arn       = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${data.terraform_remote_state.lambda_api_dev.outputs.lambda_function_name}"
  frontend_bucket_arn       = "arn:aws:s3:::${data.terraform_remote_state.frontend_dev.outputs.bucket_name}"
  frontend_distribution_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${data.terraform_remote_state.frontend_dev.outputs.distribution_id}"

  lambda_function_arn_prod       = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${data.terraform_remote_state.lambda_api_prod.outputs.lambda_function_name}"
  frontend_bucket_arn_prod       = "arn:aws:s3:::${data.terraform_remote_state.frontend_prod.outputs.bucket_name}"
  frontend_distribution_arn_prod = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${data.terraform_remote_state.frontend_prod.outputs.distribution_id}"
}

# NOTE: an AWS account can only have one OIDC provider per URL. If
# "token.actions.githubusercontent.com" is already registered (e.g. by another project),
# this resource will fail with EntityAlreadyExists — in that case, remove this resource
# block and instead reference the existing provider's ARN directly in the role below
# (data "aws_iam_openid_connect_provider" "github_actions" { url = "https://token.actions.githubusercontent.com" }).
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "github-actions-ttrpg-club-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
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

resource "aws_iam_role_policy" "deploy_permissions" {
  name = "ttrpg-club-deploy-permissions"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UpdateLambdaCode"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = [
          local.lambda_function_arn,
          local.lambda_function_arn_prod,
        ]
      },
      {
        Sid    = "SyncFrontendBucket"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          local.frontend_bucket_arn,
          "${local.frontend_bucket_arn}/*",
          local.frontend_bucket_arn_prod,
          "${local.frontend_bucket_arn_prod}/*",
        ]
      },
      {
        Sid    = "InvalidateFrontendCache"
        Effect = "Allow"
        Action = "cloudfront:CreateInvalidation"
        Resource = [
          local.frontend_distribution_arn,
          local.frontend_distribution_arn_prod,
        ]
      }
    ]
  })
}
