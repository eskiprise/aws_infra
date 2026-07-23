terraform {
  required_version = ">= 1.3.7"

  required_providers {
    aws = {
      version = "~> 4.56.0"
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
