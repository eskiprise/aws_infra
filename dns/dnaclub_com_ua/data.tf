data "terraform_remote_state" "frontend_prod" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "s3_cloudfront/ttrpg_club_frontend_prod/terraform.tfstate"
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
