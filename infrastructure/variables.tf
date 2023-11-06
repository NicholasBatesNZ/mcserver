variable "aws_region" {
  type = string
  description = "The AWS region in which to build the resources."
  default = "ap-southeast-2"
}

variable "tags" {
  type = map(string)
  description = "Tags to put on all resources"
  default = {
    "creator" = "mcdocker"
  }
}

variable "s3_bucket_name" {
  type = string
  description = "The S3 bucket in which to put the things."
  default = "mcserver-rawfiles"
}

variable "s3_manager_bucket" {
  type = string
  description = "The S3 bucket in which to put the management website."
  default = "mcserver-management"
}

variable "domain" {
  type = string
  description = "Domain for the server."
  default = "minecraft.batesnz.com"
}

variable "subdomain" {
  type = string
  description = "Subdomain for the management site."
  default = "magic"
}

variable "rcon_password" {
  type = string
  description = "Password to access server via RCON."
}

variable "discord_webhook" {
  type = string
  description = "Webhook URL to send discord messages."
}
