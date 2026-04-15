module "dynamodb_spots" {
  source = "../../modules/dynamodb"

  name     = "spots-${local.common_tags.environment}"
  hash_key = "id"
  attributes = [
    { name = "id", type = "S" },
  ]
  tags = local.common_tags
}

module "dynamodb_favorites" {
  source = "../../modules/dynamodb"

  name      = "favorites-${local.common_tags.environment}"
  hash_key  = "userId"
  range_key = "spotId"
  attributes = [
    { name = "userId", type = "S" },
    { name = "spotId", type = "S" },
  ]
  tags = local.common_tags
}

module "dynamodb_spot_submissions" {
  source = "../../modules/dynamodb"

  name     = "spot-submissions-${local.common_tags.environment}"
  hash_key = "id"
  attributes = [
    { name = "id", type = "S" },
  ]
  tags = local.common_tags
}

module "dynamodb_reviews" {
  source = "../../modules/dynamodb"

  name     = "reviews-${local.common_tags.environment}"
  hash_key = "id"
  attributes = [
    { name = "id", type = "S" },
    { name = "userId", type = "S" },
    { name = "spotId", type = "S" },
    { name = "createdAt", type = "N" },
  ]
  global_secondary_indexes = [
    {
      name      = "reviews_by_user"
      hash_key  = "userId"
      range_key = "createdAt"
    },
    {
      name      = "reviews_by_createdAt"
      hash_key  = "spotId"
      range_key = "createdAt"
    },
  ]
  tags = local.common_tags
}
