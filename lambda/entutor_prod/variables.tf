variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}

variable "admin_chat_id" {
  type        = string
  default     = "394773843"
  description = "Numeric Telegram chat ID that receives low-word-pool warnings. Not a secret, but not hardcoded in the handler either."
}

variable "send_hour" {
  type        = number
  default     = 14
  description = "Hour of the user's LOCAL day when the session is sent (24h). The scheduler runs hourly and keeps only users whose local clock matches."
}

variable "default_timezone" {
  type        = string
  default     = "Europe/Kyiv"
  description = "IANA timezone assigned to new users, and the fallback when a stored timezone is invalid."
}

variable "low_pool_threshold" {
  type        = number
  default     = 30
  description = "Warn the admin chat when a user has fewer than this many unseen words left at their level — the signal to generate the next content batch."
}

variable "sender_concurrency" {
  type        = number
  default     = null
  description = "Reserved concurrency on the sender. Throttles the daily fan-out to stay inside Telegram's ~30 messages/second global limit."
}

variable "entutor_prod_params" {
  type = map(string)
  default = {
    "/entutor/prod/bot/token"          = "Telegram bot token. Not in source control."
    "/entutor/prod/bot/webhook_secret" = "Shared secret sent by Telegram as X-Telegram-Bot-Api-Secret-Token and verified by the webhook Lambda. Not in source control."
  }
  description = "Map of SSM parameter names to descriptions. Values are placeholders — set the real value with `aws ssm put-parameter --overwrite` (Terraform ignores changes to value)."
}
