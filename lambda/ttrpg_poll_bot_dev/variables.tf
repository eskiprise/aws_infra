variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}

variable "admin_chat_id" {
  type        = string
  description = "Numeric Telegram chat ID that receives new club signup-request notifications for the dev/test bot. Not a secret, but not hardcoded either — set via -var or a .tfvars file."
  default     = "394773843"
}

variable "mini_app_deep_link" {
  type        = string
  default     = "https://t.me/ttrpgpolltestbot/stats"
  description = "https://t.me/<dev_bot_username>/<app_short_name> — set once the dev Mini App is registered via @BotFather's /newapp. Left blank until then; /stats replies with a \"temporarily unavailable\" message rather than a broken button."
}

variable "ttrpg_dev_params" {
  type = map(string)
  default = {
    "/ttrpg_club/dev/poll_bot/token"         = "Token for the development bot, stored in SSM. Not in source control."
    "/ttrpg_club/dev/telegram_admin_chat_id" = "Telegram chat ID for the admin chat, stored in SSM. Not in source control."
  }
  description = "Map of SSM parameter names to descriptions for the development bot. Values are placeholders — set the real value manually with aws ssm put-parameter (Terraform ignores changes to value)."
}
