variable "cors_allowed_origin" {
  type        = string
  default     = "*"
  description = "Origin allowed to PUT avatar uploads via presigned URL. Narrow to the deployed frontend's CloudFront domain (and/or http://localhost:5173) once known."
}
