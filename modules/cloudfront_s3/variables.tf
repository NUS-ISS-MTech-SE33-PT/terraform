variable "oac_name" {
  type        = string
  description = "Name of the Origin Access Control."
}

variable "oac_description" {
  type        = string
  description = "Description of the Origin Access Control."
  default     = ""
}

variable "s3_domain_name" {
  type        = string
  description = "Regional domain name of the S3 bucket origin."
}

variable "origin_id" {
  type        = string
  description = "Unique identifier for the origin, used in cache behavior and origin block."
}

variable "comment" {
  type        = string
  description = "Comment for the CloudFront distribution."
  default     = null
}

variable "default_root_object" {
  type        = string
  description = "Object to return when the root URL is requested (e.g. index.html). Omit for non-website origins."
  default     = null
}

variable "is_ipv6_enabled" {
  type        = bool
  description = "Whether IPv6 is enabled."
  default     = false
}

variable "price_class" {
  type        = string
  description = "CloudFront price class."
  default     = "PriceClass_200"
}

variable "web_acl_id" {
  type        = string
  description = "ARN of the WAFv2 WebACL to associate. Omit if WAF is not required."
  default     = null
}

variable "hsts_policy_name" {
  type        = string
  description = "Name for an HSTS response headers policy created inside this module. Omit if no HSTS policy is needed."
  default     = null
}

variable "custom_error_responses" {
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = optional(number, 0)
  }))
  description = "Custom error responses. Omit for distributions that do not serve a SPA."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}
