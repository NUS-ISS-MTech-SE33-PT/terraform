locals {
  aws_region            = "ap-southeast-1"
  env                   = "prod"
  bootstrap_policy_name = "terraform-bootstrap-${local.env}-policy"
}
