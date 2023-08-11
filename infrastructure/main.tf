terraform {
  backend "s3" {
    bucket = "mcserver-rawfiles"
    key = "terraform/terraform.tfstate"
  }
  
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}
