variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "Region where resources are located"
}

variable "function_name" {
  type        = string
  default     = "ttrpg-club-api"
  description = "Name of the API Lambda function"
}

variable "cors_allowed_origin" {
  type        = string
  default     = "*"
  description = "Origin allowed to call the HTTP API. Narrow this to the deployed frontend's CloudFront domain (and/or http://localhost:5173 for local dev) once known — this default is permissive only to unblock the first apply."
}
