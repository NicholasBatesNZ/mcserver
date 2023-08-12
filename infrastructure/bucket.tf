# rawfiles
resource "aws_s3_bucket" "mcserver-bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_versioning" "mcserver-versioning" {
  bucket = aws_s3_bucket.mcserver-bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mcserver-lifecycle" {
  bucket = aws_s3_bucket.mcserver-bucket.id

  rule {
    id = "Freeze zips"

    filter {
      prefix = "zips"
    }

    noncurrent_version_transition {
      noncurrent_days = 7
      storage_class = "GLACIER_IR"
    }

    transition {
      days = 7
      storage_class = "GLACIER_IR"
    }

    status = "Enabled"
  }
}

# website
resource "aws_s3_bucket" "mcserver-management-bucket" {
  bucket = var.s3_manager_bucket
}

resource "aws_s3_bucket_website_configuration" "management-website-s3" {
  bucket = aws_s3_bucket.mcserver-management-bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "management-website-public-allow" {
  bucket = aws_s3_bucket.mcserver-management-bucket.id
}

resource "aws_s3_bucket_policy" "management-website-public-access-policy" {
  bucket = aws_s3_bucket.mcserver-management-bucket.id
  policy = data.aws_iam_policy_document.management-website-public-access-policy-data.json
}

data "aws_iam_policy_document" "management-website-public-access-policy-data" {
  statement {
    principals {
      type = "AWS"
      identifiers = [ "*" ]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.mcserver-management-bucket.arn}/*",
    ]
  }
}