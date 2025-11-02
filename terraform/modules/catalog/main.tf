variable "env" {
  type = string
}

resource "aws_dynamodb_table" "puuids" {
  name         = "riotlake-${var.env}-puuids"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "puuid"

  # Primary key
  attribute {
    name = "puuid"
    type = "S"
  }

  # Sort or secondary query key (for GSI)
  attribute {
    name = "next_poll_at"
    type = "N"
  }

  # Global Secondary Index for querying "due" PUUIDs
  global_secondary_index {
    name               = "gsi_next_poll"
    hash_key           = "next_poll_at"
    projection_type    = "ALL"
  }

  ttl {
    attribute_name = "ttl_epoch" # optional TTL support
    enabled        = false
  }

  tags = {
    Project = "riotlake"
    Env     = var.env
  }
}