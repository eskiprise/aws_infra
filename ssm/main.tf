resource "aws_ssm_parameter" "param" {
  for_each = var.parameters
  name  = each.key
  description = each.value
  type  = "SecureString"
  value = "replace_me!"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
