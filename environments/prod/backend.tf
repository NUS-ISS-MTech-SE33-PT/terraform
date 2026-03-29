terraform {
  backend "s3" {
    bucket       = "terraform-state-bucket-d55fab13-921142537307-ap-southeast-1-an"
    key          = "prod/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}