resource "aws_dynamodb_table" "favorites" {
  name         = "favorites-prod"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "userId"
  range_key = "spotId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "spotId"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}