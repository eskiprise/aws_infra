terraform {
  required_version = ">= 1.3.7"

  required_providers {
    aws = {
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "compliment-bot-terraform-state"
    key            = "monitoring/ttrpg_club_prod_alerts/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-lock"
  }
}
