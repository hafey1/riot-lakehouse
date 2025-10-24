resource "random_id" "suffix" { byte_length = 2 }

resource "aws_s3_bucket" "this" {
  bucket = "${var.bucket_name_prefix}-${random_id.suffix.hex}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "v" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = "Enabled" }
}

output "bucket" { value = aws_s3_bucket.this.bucket }
output "bucket_arn" { value = aws_s3_bucket.this.arn }