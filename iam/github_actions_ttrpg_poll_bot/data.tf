data "aws_caller_identity" "current" {}

# An AWS account can only have ONE OIDC provider per URL — the github_actions_ttrpg_club
# module already created "token.actions.githubusercontent.com" for the website's pipeline,
# so this one is referenced (not recreated) and reused for a second, independently-scoped
# role trusting a different GitHub repo.
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}
