variable "project" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "aws_profile" { type = string }


variable "shard_count" { type = number }
variable "firehose_buffer_mb" { type = number }
variable "firehose_buffer_seconds" { type = number }