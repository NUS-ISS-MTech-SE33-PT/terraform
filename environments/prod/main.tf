resource "aws_kms_key" "dynamodb_key" {
  description              = "KMS key for DynamoDB review table"
  deletion_window_in_days  = 7
  enable_key_rotation      = true
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
}