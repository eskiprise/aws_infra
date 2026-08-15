variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}

variable "mini_app_deep_link" {
  type        = string
  default     = "https://t.me/ttrpgpolltestbot/stats"
  description = "https://t.me/<dev_bot_username>/<app_short_name> — set once the dev Mini App is registered via @BotFather's /newapp. Left blank until then; /stats replies with a \"temporarily unavailable\" message rather than a broken button."
}

variable "bot_username" {
  type        = string
  default     = "ttrpgpolltestbot"
  description = "This bot's own @username (no leading @), used in the rejection message sent to unauthorized groups so people know where to DM it."
}

variable "club_website_url" {
  type        = string
  default     = "https://d28xo3obfyuqfl.cloudfront.net"
  description = "URL of the club's (dev) website, linked from /start. Empty until you set it — /start is sent without a website button until then."
}

variable "ttrpg_dev_params" {
  type = map(string)
  default = {
    "/ttrpg_club/dev/poll_bot/token"         = "Token for the development bot, stored in SSM. Not in source control."
    "/ttrpg_club/dev/telegram_admin_chat_id" = "Telegram chat ID that receives new club signup-request notifications for the dev/test bot, stored in SSM. Not in source control."
    "/ttrpg_club/dev/telegram_club_chat_id"  = "The only Telegram group/supergroup the dev/test bot will operate in ('Dice & Adventures TEST'), stored in SSM. Not in source control."
  }
  description = "Map of SSM parameter names to descriptions for the development bot. Values are placeholders — set the real value manually with aws ssm put-parameter (Terraform ignores changes to value)."
}
