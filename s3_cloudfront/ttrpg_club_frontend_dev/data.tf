data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = "compliment-bot-terraform-state"
    key    = "dns/dnaclub_com_ua/terraform.tfstate"
    region = "eu-west-2"
  }
}
