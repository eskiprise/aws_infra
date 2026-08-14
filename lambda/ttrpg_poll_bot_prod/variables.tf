variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}

variable "mini_app_deep_link" {
  type        = string
  default     = "https://t.me/ttrpgpollbot/stats"
  description = "https://t.me/<bot_username>/<app_short_name> — set once the Mini App is registered via @BotFather's /newapp. Left blank until then; /stats replies with a \"temporarily unavailable\" message rather than a broken button."
}

variable "bot_username" {
  type        = string
  default     = "ttrpgpollbot"
  description = "This bot's own @username (no leading @), used in the rejection message sent to unauthorized groups so people know where to DM it."
}

variable "ttrpg_prod_params" {
  type = map(string)
  default = {
    "/ttrpg_club/prod/poll_bot/token"         = "Token for the production bot, stored in SSM. Not in source control."
    "/ttrpg_club/prod/telegram_admin_chat_id" = "Telegram chat ID that receives new club signup-request notifications, stored in SSM. Not in source control."
    "/ttrpg_club/prod/telegram_club_chat_id"  = "The only Telegram group/supergroup the production bot will operate in — the real club chat, stored in SSM. Not in source control."
  }
  description = "Map of SSM parameter names to descriptions for the production bot. Values are placeholders — set the real value manually with aws ssm put-parameter (Terraform ignores changes to value)."
}
