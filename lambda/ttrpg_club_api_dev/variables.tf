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

variable "cors_allowed_origin" {
  type        = string
  default     = "*"
  description = "Origin allowed to call the HTTP API. Narrow this to the deployed frontend's CloudFront domain (and/or http://localhost:5173 for local dev) once known — this default is permissive only to unblock the first apply."
}

variable "reserved_concurrency" {
  type        = number
  default     = -1
  description = "Hard cap on concurrent Lambda executions, regardless of incoming request volume. -1 means unset (no reservation) — this account's total concurrency quota is too low to reserve any amount right now (AWS requires at least 10 unreserved for the rest of the account). Check `aws lambda get-account-settings --query 'AccountLimit.ConcurrentExecutions'` and set a value here (leaving room for the account's other Lambdas + a 10 floor) if you want this cap back."
}

variable "throttling_rate_limit" {
  type        = number
  default     = 10
  description = "Steady-state requests/second the API Gateway stage accepts across all callers combined before returning 429. A blunt, account-wide (not per-IP) limit — cheap first line of defense against a request flood driving up Lambda/DynamoDB costs."
}

variable "throttling_burst_limit" {
  type        = number
  default     = 20
  description = "Short burst of requests allowed above the steady-state rate limit before 429s kick in."
}
