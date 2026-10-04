resource "aws_s3_bucket" "terraform_state" {
  #checkov:skip=CKV_AWS_18:A separate access-log bucket is intentionally omitted from this small personal lab.
  #checkov:skip=CKV_AWS_144:Cross-region replication is outside the scope of this single-region lab.
  #checkov:skip=CKV_AWS_145:SSE-S3 is used to avoid a continuously billed customer-managed KMS key in this lab.
  #checkov:skip=CKV2_AWS_62:Event notifications are not required for a Terraform state bucket in this lab.

  bucket = var.backend_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
