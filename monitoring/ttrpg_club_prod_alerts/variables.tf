variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}

variable "admin_chat_id" {
  type        = string
  default     = "394773843"
  description = "Telegram chat ID to DM error alerts to — same value as lambda/ttrpg_poll_bot_prod's admin_chat_id, since this reuses that bot to send the DM rather than registering a separate one."
}
