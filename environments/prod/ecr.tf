resource "aws_ecr_repository" "review_service" {
  name = "makango-review-service"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "spot_service" {
  name = "makango-spot-service"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "spot_submission_service" {
  name = "makango-spot-submission-service"
  image_scanning_configuration {
    scan_on_push = true
  }
}
