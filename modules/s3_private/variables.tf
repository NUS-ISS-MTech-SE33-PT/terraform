variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket."
}

variable "cloudfront_distribution_arn" {
  type        = string
  description = "ARN of the CloudFront distribution allowed to access this bucket."
}

variable "lifecycle_rules" {
  type = list(object({
    id              = string
    prefix          = optional(string)
    expiration_days = optional(number)
  }))
  description = "Lifecycle rules to apply. Omit for buckets with no expiry policy."
  default     = []
}

variable "cors_rules" {
  type = list(object({
    allowed_headers = optional(list(string), [])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 0)
  }))
  description = "CORS rules to apply. Omit for buckets not accessed directly from browsers."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}
