variable "github_repo" {
  type        = string
  default     = "eskiprise@193757156/ttrpg_website@1307463320"
  description = "GitHub \"org/repo\" allowed to assume the deploy role — only its main branch."
}

variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}
