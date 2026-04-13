resource "aws_dynamodb_table" "spot_submissions" {
  name         = "spot-submissions-prod"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}
