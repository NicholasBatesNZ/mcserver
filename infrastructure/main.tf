terraform {
  backend "s3" {
    region = "ap-southeast-2"
    bucket = "mcserver-rawfiles"
    key = "terraform/terraform.tfstate"
    profile = "mc"
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
  profile = var.aws_profile
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  profile = var.aws_profile
  
  default_tags {
    tags = var.tags
  }
}
