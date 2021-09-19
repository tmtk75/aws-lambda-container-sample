resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket_name
  acl    = "private"

  lifecycle_rule {
    enabled = true
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = 200
      storage_class = "GLACIER"
    }
  }
}


