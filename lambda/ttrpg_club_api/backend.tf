terraform {
  required_version = ">= 1.3.7"

  required_providers {
    aws = {
      # Newer than the rest of the repo (~> 4.56.0) specifically because nodejs20.x/22.x
      # runtime support requires it — the other ttrpg_club_* modules don't need this.
      version = "~> 6.0"
    }
    template = {
      version = "~> 2.2.0"
    }
  }

  backend "s3" {
    bucket         = "compliment-bot-terraform-state"
    key            = "lambda/ttrpg_club_api/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-lock"
  }
}
