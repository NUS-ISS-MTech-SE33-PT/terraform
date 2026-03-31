#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="ap-southeast-1"
BUCKET_NAME="terraform-state-bucket-${ACCOUNT_ID}-${REGION}"
ENV="prod"

echo "Creating S3 bucket: $BUCKET_NAME"

aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Block all public access
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable versioning (allows state recovery)
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "Done! Use this in your backend.tf:"
echo ""
echo "  backend \"s3\" {"
echo "    bucket       = \"$BUCKET_NAME\""
echo "    key          = \"$ENV/terraform.tfstate\""
echo "    region       = \"$REGION\""
echo "    encrypt      = true"
echo "    use_lockfile = true"
echo "  }"