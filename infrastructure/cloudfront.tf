resource "aws_route53_zone" "mcserver-zone" {
  name = var.domain
}

resource "aws_route53_record" "management-record" {
  zone_id = aws_route53_zone.mcserver-zone.id
  name = "${var.subdomain}.${var.domain}"
  type = "A"

  alias {
    name = aws_cloudfront_distribution.management-distribution.domain_name
    zone_id = aws_cloudfront_distribution.management-distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_control" "management-distribution-access-control" {
  name = "management-distribution-access-control"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_acm_certificate" "management-cert" {
  domain_name = "${var.subdomain}.${var.domain}"
  validation_method = "DNS"
  provider = aws.us_east_1
}

resource "aws_cloudfront_distribution" "management-distribution" {
  origin {
    domain_name = aws_s3_bucket.mcserver-management-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.management-distribution-access-control.id
    origin_id = "management-distribution-origin"
  }

  default_root_object = "index.html"

  enabled = true

  aliases = [ "${var.subdomain}.${var.domain}" ]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.management-cert.arn
    ssl_support_method = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods = [ "GET", "HEAD" ]
    cached_methods = [ "GET", "HEAD" ]
    viewer_protocol_policy = "redirect-to-https"
    target_origin_id = "management-distribution-origin"
    compress = true
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }
}