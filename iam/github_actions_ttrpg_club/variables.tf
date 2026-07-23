variable "github_repo" {
  type        = string
  default     = "eskiprise/ttrpg_website"
  description = "GitHub \"org/repo\" allowed to assume the deploy role — only its main branch."
}

variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}
