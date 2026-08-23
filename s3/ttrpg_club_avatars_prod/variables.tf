variable "cors_allowed_origins" {
  type = list(string)
  default = [
    "https://dnaclub.com.ua",
  ]
  description = "Origins allowed to PUT avatar uploads via presigned URL."
}
