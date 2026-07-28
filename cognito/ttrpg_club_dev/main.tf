# Dev counterpart to ../ttrpg_club_prod — same shape, separate user pool. Replaces the
# old unsuffixed ../ttrpg_club module (retire that one via `terraform destroy` once this
# is applied and cut over — see aws_infra/README.md).

resource "aws_cognito_user_pool" "ttrpg_club" {
  name = "ttrpg-club-dev"

  # No public self-signup: members only become real Cognito users when an admin
  # approves their signup request and the API calls AdminCreateUser.
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "given_name"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "family_name"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  tags = {
    Terraform   = "true"
    Project     = "ttrpg-club"
    Environment = "development"
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "ttrpg-club-dev-web"
  user_pool_id = aws_cognito_user_pool.ttrpg_club.id

  generate_secret               = false
  explicit_auth_flows           = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors = "ENABLED"
  access_token_validity         = 1
  id_token_validity             = 1
  refresh_token_validity        = 30
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.ttrpg_club.id
  description  = "Club admins — can approve signups and edit official game/stats data"
}
