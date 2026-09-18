variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}

variable "function_name" {
  type        = string
  default     = "ttrpg-club-api-dev"
  description = "Name of the API Lambda function"
}

variable "admin_telegram_ids" {
  type        = list(string)
  default     = ["394773843", "295611333"]
  description = "Telegram user ids (as strings) granted admin access — checked per-request, not baked into a session token, so a change here takes effect on next apply without anyone needing to log in again."
}

variable "dev_login_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Shared secret for POST /auth/dev-login, the local-dev workaround for the Telegram Login Widget only working on its registered domain. Empty means the route is disabled (process.env.DEV_LOGIN_SECRET is falsy) — set a real value here to use `npm run dev:frontend` with a working login."
}

variable "cors_allowed_origins" {
  type = list(string)
  default = [
    "https://dev.dnaclub.com.ua",
    "http://localhost:5173", # npm run dev:frontend points at this deployed dev API directly
  ]
  description = "Origins allowed to call the HTTP API."
}

variable "reserved_concurrency" {
  type        = number
  default     = -1
  description = "Hard cap on concurrent Lambda executions, regardless of incoming request volume. -1 means unset (no reservation) — this account's total concurrency quota is too low to reserve any amount right now (AWS requires at least 10 unreserved for the rest of the account). Check `aws lambda get-account-settings --query 'AccountLimit.ConcurrentExecutions'` and set a value here (leaving room for the account's other Lambdas + a 10 floor) if you want this cap back."
}

variable "throttling_rate_limit" {
  type        = number
  default     = 25
  description = "Steady-state requests/second the API Gateway stage accepts across all callers combined before returning 429. A blunt, account-wide (not per-IP) limit — cheap first line of defense against a request flood driving up Lambda/DynamoDB costs. Was 10 — too low for legitimate admin bursts (e.g. reordering several items in the media gallery each fires 2 PATCH + 2 CORS preflights), which tripped it in normal use, not abuse."
}

variable "throttling_burst_limit" {
  type        = number
  default     = 50
  description = "Short burst of requests allowed above the steady-state rate limit before 429s kick in."
}

variable "club_chat_thread_id" {
  type        = string
  default     = "2"
  description = "Forum topic in the club chat where /rate polls live — a Mini App poll is posted into the same one. Empty for a chat without topics."
}

variable "mini_app_deep_link" {
  type        = string
  default     = "https://t.me/ttrpgpolltestbot/stats"
  description = "Same value as ttrpg_poll_bot_dev's variable of this name — used for the \"leave feedback\" button posted next to a poll created from the Mini App."
}
