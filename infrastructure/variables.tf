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
  description = "The S3 bucket in which to put all the things."
  default = "mcserver-rawfiles"
}

variable "domain" {
  type = string
  description = "Domain for the server."
  default = "minecraft.batesnz.com"
}
