locals {
  ecr_repositories = toset([
    "makango-review-service",
    "makango-spot-service",
    "makango-spot-submission-service",
  ])
}

resource "aws_ecr_repository" "services" {
  for_each = local.ecr_repositories

  name = each.key

  image_scanning_configuration {
    scan_on_push = true
  }
}

moved {
  from = aws_ecr_repository.review_service
  to   = aws_ecr_repository.services["makango-review-service"]
}

moved {
  from = aws_ecr_repository.spot_service
  to   = aws_ecr_repository.services["makango-spot-service"]
}

moved {
  from = aws_ecr_repository.spot_submission_service
  to   = aws_ecr_repository.services["makango-spot-submission-service"]
}
