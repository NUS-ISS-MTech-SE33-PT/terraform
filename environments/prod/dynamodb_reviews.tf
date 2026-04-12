resource "aws_dynamodb_table" "reviews" {
  name         = "reviews-prod"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "spotId"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }

  global_secondary_index {
    name            = "reviews_by_user"
    projection_type = "ALL"
    key_schema {
      attribute_name = "userId"
      key_type       = "HASH"
    }
    key_schema {
      attribute_name = "createdAt"
      key_type       = "RANGE"
    }
  }

  global_secondary_index {
    name            = "reviews_by_createdAt"
    projection_type = "ALL"
    key_schema {
      attribute_name = "spotId"
      key_type       = "HASH"
    }
    key_schema {
      attribute_name = "createdAt"
      key_type       = "RANGE"
    }
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "N"
  }

  server_side_encryption {
    enabled = true
  }
}