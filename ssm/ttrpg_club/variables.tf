variable "parameters" {
  type        = map(string)
  description = "List of ssm parameter names to create placeholders for the club's dedicated Telegram bot"

  default = {
    "/ttrpg-club/telegram-bot-token"     = "Bot token for the club's dedicated signup-notification Telegram bot"
    "/ttrpg-club/telegram-admin-chat-id" = "Telegram chat ID the Notifier Lambda posts new signup requests to"
  }
}
