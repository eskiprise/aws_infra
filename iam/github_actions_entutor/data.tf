data "aws_caller_identity" "current" {}

# An AWS account can only have ONE OIDC provider per URL — github_actions_ttrpg_club
# already created "token.actions.githubusercontent.com", so this module references
# (not recreates) it and attaches an independently-scoped role for a different repo.
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}
