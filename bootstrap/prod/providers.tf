provider "aws" {
  default_tags {
    tags = {
      environment = "prod"
      project     = "makan-go"
      managed_by  = "terraform"
    }
  }
}