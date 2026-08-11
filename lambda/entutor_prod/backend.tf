terraform {
  required_version = ">= 1.3.7"

  required_providers {
    aws = {
      # Newer than the older modules in this repo (~> 4.56.0) because the
      # python3.14 runtime needs it — same reason lambda/ttrpg_poll_bot_prod
      # and lambda/ttrpg_club_api pin ~> 6.0.
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "compliment-bot-terraform-state"
    key            = "lambda/entutor_prod/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-lock"
  }
}
