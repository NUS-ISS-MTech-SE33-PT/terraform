locals {
  aws_region = "ap-southeast-1"
  account_id = "921142537307"
  common_tags = {
    environment = "prod"
    project     = "makan-go"
    managed_by  = "terraform"
  }
}
