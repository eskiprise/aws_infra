terraform {
  required_version = ">= 1.3.7"

  required_providers {
    aws = {
      # Newer than the rest of the repo (~> 4.56.0) specifically because python3.13/3.14
      # runtime support requires it — matches why lambda/ttrpg_club_api also pins ~> 6.0.
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "compliment-bot-terraform-state"
    key            = "lambda/ttrpg_poll_bot_dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-lock"
  }
}
