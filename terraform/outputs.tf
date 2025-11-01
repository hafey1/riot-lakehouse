output "bucket" {
  description = "S3 bucket for bronze landing (randomized suffix)."
  value       = module.storage.bucket
}

output "stream_name" {
  description = "Kinesis data stream receiving raw events."
  value       = module.streaming.stream_name
}

output "delivery_name" {
  description = "Kinesis Firehose delivery stream writing to S3."
  value       = module.streaming.delivery_name
}

output "secret_name" {
  description = "Secrets Manager path where the Riot API key is stored."
  value       = module.secret.secret_name
}