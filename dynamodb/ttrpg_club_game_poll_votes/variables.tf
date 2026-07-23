variable "attributes" {
  type        = list(map(string))
  description = "Attributes DynamoDB is going to have"

  default = [
    {
      name = "gameId"
      type = "S"
    },
    {
      name = "userId"
      type = "S"
    }
  ]
}
