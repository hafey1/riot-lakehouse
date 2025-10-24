data "aws_caller_identity" "me" {}

locals {
  kinesis_stream_arn = "arn:aws:kinesis:${var.region}:${data.aws_caller_identity.me.account_id}:stream/${var.stream_name}"
}

resource "aws_iam_role" "firehose" {
  name = "riotFirehoseRole-${var.region}-${var.stream_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "firehose.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "firehose_policy" {
  role = aws_iam_role.firehose.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "S3"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:AbortMultipartUpload", "s3:ListBucket", "s3:GetBucketLocation"]
        Resource = [var.bucket_arn, "${var.bucket_arn}/*"]
      },
      {
        Sid      = "Kinesis"
        Effect   = "Allow"
        Action   = ["kinesis:DescribeStream", "kinesis:GetShardIterator", "kinesis:GetRecords", "kinesis:ListShards"]
        Resource = local.kinesis_stream_arn
      },
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

output "firehose_role_arn" { value = aws_iam_role.firehose.arn }