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

module "lambda_ingest" {
  source        = "./modules/lambda"
  region        = var.region
  function_name = "${local.prefix}-ingester"
  role_name     = "${local.prefix}-lambda-role"
  zip_path      = abspath("${path.root}/../lambda_ingest/lambda.zip")
  handler       = "lambda_ingest.app.handler"
  runtime       = "python3.11"

  env_vars = {
    ENV            = var.env
    KINESIS_STREAM = "${local.prefix}-matches-raw"
    SECRET_NAME    = "${var.project}/${var.env}/api-key"
    RIOT_BASE_URL  = "https://americas.api.riotgames.com"
  }

  # Schedule can be turned off or tuned per env later via tfvars
  create_schedule     = true
  schedule_expression = "rate(5 minutes)"

  tags = local.tags
}