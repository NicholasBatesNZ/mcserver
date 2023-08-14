resource "aws_ecrpublic_repository" "mcserver-repo" {
  repository_name = "mcserver"
  provider = aws.us_east_1
}
