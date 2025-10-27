
data "aws_caller_identity" "me" {}

# IAM role for Lambda
resource "aws_iam_role" "lambda" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

# Inline policy: logs, Secrets Manager read, Kinesis put
resource "aws_iam_role_policy" "lambda_inline" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid : "Logs",
        Effect : "Allow",
        Action : ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource : "arn:aws:logs:*:*:*"
      },
      {
        Sid : "SecretsRead",
        Effect : "Allow",
        Action : ["secretsmanager:GetSecretValue"],
        Resource : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.me.account_id}:secret:*"
      },
      {
        Sid : "KinesisPut",
        Effect : "Allow",
        Action : ["kinesis:PutRecord", "kinesis:PutRecords", "kinesis:DescribeStream", "kinesis:DescribeStreamSummary"],
        Resource : "arn:aws:kinesis:${var.region}:${data.aws_caller_identity.me.account_id}:stream/*"
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.lambda.arn
  handler       = var.handler
  runtime       = var.runtime
  filename      = var.zip_path
  architectures = ["x86_64"]
  memory_size   = 512
  timeout       = 30
  publish       = true

  environment {
    variables = var.env_vars
  }

  tags = var.tags
}

# Optional: EventBridge schedule -> Lambda
resource "aws_cloudwatch_event_rule" "schedule" {
  count               = var.create_schedule ? 1 : 0
  name                = "${var.function_name}-schedule"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "to_lambda" {
  count     = var.create_schedule ? 1 : 0
  rule      = aws_cloudwatch_event_rule.schedule[0].name
  target_id = "invoke-lambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_events" {
  count         = var.create_schedule ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule[0].arn
}

output "function_name" { value = aws_lambda_function.this.function_name }
output "role_name" { value = aws_iam_role.lambda.name }