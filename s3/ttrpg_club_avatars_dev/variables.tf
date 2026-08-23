variable "cors_allowed_origins" {
  type = list(string)
  default = [
    "https://dev.dnaclub.com.ua",
    "http://localhost:5173", # npm run dev:frontend uploads avatars straight to this bucket
  ]
  description = "Origins allowed to PUT avatar uploads via presigned URL."
}
