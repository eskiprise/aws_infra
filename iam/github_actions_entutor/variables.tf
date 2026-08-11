variable "github_repo" {
  type    = string
  default = "eskiprise@193757156/entutor@1320093996"
  # eskiprise has "immutable IDs" enabled, so the OIDC token's `sub` claim is
  # "repo:eskiprise@<ownerId>/entutor@<repoId>:ref:..." rather than the plain
  # "org/repo" form — same as ttrpg_poll_bot and ttrpg_club (see
  # iam/github_actions_ttrpg_poll_bot/variables.tf). Owner id 193757156 matches
  # both sibling modules (same account); repo id 1320093996 confirmed via
  # `gh api repos/eskiprise/entutor --jq '{repo_id: .id, owner_id: .owner.id}'`.
  description = "GitHub \"org/repo\" allowed to assume the deploy role."
}

variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}
