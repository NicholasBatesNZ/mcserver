provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  default_tags {
    tags = var.tags
  }
}

resource "aws_ecrpublic_repository" "mcserver-repo" {
  repository_name = "mcserver"
  provider = aws.us_east_1
}
