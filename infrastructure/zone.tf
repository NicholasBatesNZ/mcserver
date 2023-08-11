resource "aws_route53_zone" "mcserver-zone" {
  name = var.domain
}

resource "aws_route53_record" "mcserver-record" {
  zone_id = aws_route53_zone.mcserver-zone.id
  name = var.domain
  type = "A"
  records = [ "96.0.73.34" ]
  ttl = 172800
}