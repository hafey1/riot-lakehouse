resource "aws_secretsmanager_secret" "this" {
  name = var.secret_name
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({ RIOT_API_KEY = "REPLACE_ME" })
}

output "secret_name" { value = aws_secretsmanager_secret.this.name }