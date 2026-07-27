output "deploy_role_arn" {
  value       = aws_iam_role.github_actions_deploy.arn
  sensitive   = false
  description = "Set as the AWS_DEPLOY_ROLE_ARN secret in the ttrpg_poll_bot GitHub repo"
}
