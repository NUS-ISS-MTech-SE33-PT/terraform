locals {
  aws_region = "ap-southeast-1"
  common_tags = {
    environment = "prod"
    project     = "makan-go"
    managed_by  = "terraform"
  }
}
