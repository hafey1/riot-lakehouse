resource "aws_kinesis_stream" "this" {
  name             = var.stream_name
  shard_count      = var.shard_count
  retention_period = 24
  stream_mode_details { stream_mode = "PROVISIONED" }
  tags = var.tags
}

resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = var.delivery_name
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.this.arn
    role_arn           = var.firehose_role_arn
  }

  extended_s3_configuration {
    role_arn            = var.firehose_role_arn
    bucket_arn          = var.bucket_arn
    prefix              = var.s3_prefix
    error_output_prefix = var.s3_error_prefix
    buffering_size      = var.firehose_buffer_mb
    buffering_interval  = var.firehose_buffer_seconds
    compression_format  = "GZIP"
  }

  tags = var.tags
}

output "stream_name" { value = aws_kinesis_stream.this.name }
output "delivery_name" { value = aws_kinesis_firehose_delivery_stream.this.name }