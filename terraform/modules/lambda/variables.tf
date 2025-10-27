variable "function_name" { type = string }
variable "region" { type = string }
variable "role_name" { type = string }
variable "zip_path" { type = string } # e.g. ../lambda_ingest/lambda.zip
variable "handler" { type = string }  # e.g. "lambda_ingest.app.handler"
variable "runtime" { type = string }  # e.g. "python3.11"

variable "env_vars" {
  type = map(string) # multi-line form needed
}

variable "tags" { type = map(string) }

variable "create_schedule" {
  type    = bool
  default = true
}

variable "schedule_expression" {
  type    = string
  default = "rate(5 minutes)"
}