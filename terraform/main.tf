locals {
  prefix = "${var.project}-${var.env}"
  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

module "storage" {
  source             = "./modules/storage"
  bucket_name_prefix = "${local.prefix}-bronze"
  tags               = local.tags
}

module "iam" {
  source      = "./modules/iam"
  region      = var.region
  stream_name = "${local.prefix}-matches-raw"
  bucket_arn  = module.storage.bucket_arn
  tags        = local.tags
}

module "streaming" {
  source                  = "./modules/streaming"
  region                  = var.region
  stream_name             = "${local.prefix}-matches-raw"
  delivery_name           = "${local.prefix}-raw-to-s3"
  shard_count             = var.shard_count
  bucket_arn              = module.storage.bucket_arn
  bucket_name             = module.storage.bucket
  firehose_role_arn       = module.iam.firehose_role_arn
  s3_prefix               = "bronze/matches/env=${var.env}/date=!{timestamp:yyyy-MM-dd}/"
  s3_error_prefix         = "errors/env=${var.env}/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
  firehose_buffer_mb      = var.firehose_buffer_mb
  firehose_buffer_seconds = var.firehose_buffer_seconds
  tags                    = local.tags
}

module "secret" {
  source      = "./modules/secret"
  secret_name = "${var.project}/${var.env}/api-key"
  tags        = local.tags
}

output "bucket" { value = module.storage.bucket }
output "stream_name" { value = module.streaming.stream_name }
output "delivery_name" { value = module.streaming.delivery_name }
output "secret_name" { value = module.secret.secret_name }
