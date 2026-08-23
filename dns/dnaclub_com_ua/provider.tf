provider "aws" {
  region = "eu-west-2"
}

# CloudFront only accepts ACM certificates issued in us-east-1, regardless of which
# region the rest of a stack lives in — this alias exists solely for that requirement.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
