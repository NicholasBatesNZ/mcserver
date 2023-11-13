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

resource "aws_s3_bucket_public_access_block" "mcserver-private" {
  bucket = aws_s3_bucket.mcserver-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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
      storage_class   = "GLACIER_IR"
    }

    transition {
      days          = 7
      storage_class = "GLACIER_IR"
    }

    status = "Enabled"
  }

  rule {
    id = "Freeze lambda sources"

    filter {
      prefix = "lambda_sources"
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "rawfiles_notification" {
  bucket = aws_s3_bucket.mcserver-bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.run_codebuild.arn
    filter_prefix       = "zips/"
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.codebuild_lambda_allow_bucket]
}

# website
resource "aws_s3_bucket" "mcserver-management-bucket" {
  bucket = var.s3_manager_bucket
}

resource "aws_s3_bucket_public_access_block" "management-bucket-private" {
  bucket = aws_s3_bucket.mcserver-management-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "management-policy-cloudfront" {
  bucket = aws_s3_bucket.mcserver-management-bucket.id
  policy = data.aws_iam_policy_document.management-allow-cloudfront.json
}

data "aws_iam_policy_document" "management-allow-cloudfront" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.mcserver-management-bucket.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::251780365797:distribution/${aws_cloudfront_distribution.management-distribution.id}"]
    }
  }
}
