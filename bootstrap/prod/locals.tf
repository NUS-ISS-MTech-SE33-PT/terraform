data "aws_caller_identity" "current" {}

locals {
  aws_region            = "ap-southeast-1"
  env                   = "prod"
  project               = "makan-go"
  bootstrap_policy_name = "terraform-${local.project}-${local.env}-bootstrap-policy"
  account_id            = data.aws_caller_identity.current.account_id
  bucket_arn            = "arn:aws:s3:::terraform-state-bucket-${local.account_id}-${local.aws_region}"
}
