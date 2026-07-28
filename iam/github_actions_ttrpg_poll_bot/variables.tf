variable "github_repo" {
  type        = string
  default     = "eskiprise@193757156/ttrpg_poll_bot@1133133400"
  # If AssumeRoleWithWebIdentity fails with a sub-claim mismatch, this GitHub account may
  # have "immutable IDs" enabled (as eskiprise/ttrpg_website did) — the OIDC token's `sub`
  # claim then looks like "repo:EskiSlav@<ownerId>/ttrpg_poll_bot@<repoId>:ref:..." instead
  # of the plain-name form below. Decode the token's payload in a debug workflow step to
  # check, then update this default to match if so (see iam/github_actions_ttrpg_club's
  # own history for exactly this fix).
  description = "GitHub \"org/repo\" allowed to assume the deploy role — only its main branch."
}

variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}
