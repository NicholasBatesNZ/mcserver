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