variable "attributes" {
  type        = list(map(string))
  description = "Attributes DynamoDB is going to have"

  default = [
    {
      name = "pollId"
      type = "S"
    }
  ]
}
