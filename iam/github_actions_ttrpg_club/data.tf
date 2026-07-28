data "aws_caller_identity" "current" {}

data "terraform_remote_state" "lambda_api_dev" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "lambda/ttrpg_club_api/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "frontend_dev" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "s3_cloudfront/ttrpg_club_frontend_dev/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "lambda_api_prod" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "lambda/ttrpg_club_api_prod/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "frontend_prod" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "s3_cloudfront/ttrpg_club_frontend_prod/terraform.tfstate"
    region = "eu-west-2"
  }
}
