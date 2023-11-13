resource "aws_ssm_parameter" "rcon_password" {
  name  = "mc-rcon-password"
  type  = "SecureString"
  value = var.rcon_password
}
