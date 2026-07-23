variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}

variable "function_name" {
  type        = string
  default     = "ttrpg-club-notifier"
  description = "Name of the Notifier Lambda function"
}
