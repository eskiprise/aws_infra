variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}

variable "admin_chat_id" {
  type        = string
  description = "Numeric Telegram chat ID that receives new club signup-request notifications. Not a secret, but not hardcoded either — set via -var or a .tfvars file."
  default     = "394773843"
}

variable "mini_app_deep_link" {
  type        = string
  default     = "https://t.me/ttrpgpollbot/stats"
  description = "https://t.me/<bot_username>/<app_short_name> — set once the Mini App is registered via @BotFather's /newapp. Left blank until then; /stats replies with a \"temporarily unavailable\" message rather than a broken button."
}
