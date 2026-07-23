variable "attributes" {
  type        = list(map(string))
  description = "Attributes DynamoDB is going to have"

  default = [
    {
      name = "requestId"
      type = "S"
    },
    {
      name = "status"
      type = "S"
    }
  ]
}
