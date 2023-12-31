variable "aws_region" {
  type        = string
  description = "The AWS region in which to build the resources."
  default     = "ap-southeast-2"
}

variable "aws_availability_zone" {
  type        = string
  description = "Availability (or local) zone in the specified region"
  default     = "ap-southeast-2-akl-1a"
}

variable "aws_account_id" {
  type        = number
  description = "AWS Account ID"
  default     = 251780365797
}

variable "tags" {
  type        = map(string)
  description = "Tags to put on all resources"
  default = {
    "creator" = "mcdocker"
  }
}

variable "s3_bucket_name" {
  type        = string
  description = "The S3 bucket in which to put the things."
  default     = "mcserver-rawfiles"
}

variable "s3_manager_bucket" {
  type        = string
  description = "The S3 bucket in which to put the management website."
  default     = "mcserver-management"
}

variable "github_repo" {
  type        = string
  description = "This GitHub repository in format ORG/REPO"
  default     = "NicholasBatesNZ/mcserver"
}

variable "domain" {
  type        = string
  description = "Domain for the server."
  default     = "minecraft.batesnz.com"
}

variable "subdomain" {
  type        = string
  description = "Subdomain for the management site."
  default     = "magic"
}
