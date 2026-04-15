variable "name" {
  type        = string
  description = "Name for the HTTP API."
}

variable "stage_name" {
  type        = string
  description = "Name of the API Gateway stage."
}

variable "cors_allow_origins" {
  type        = list(string)
  description = "Allowed origins for CORS."
}

variable "access_log_destination_arn" {
  type        = string
  description = "ARN of the CloudWatch log group for API Gateway access logs."
}

variable "cognito_issuer" {
  type        = string
  description = "JWT issuer URL (Cognito user pool endpoint)."
}

variable "vpc_link_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the VPC link."
}

variable "vpc_link_security_group_ids" {
  type        = list(string)
  description = "Security group IDs for the VPC link."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}

variable "services" {
  type = map(object({
    listener_arn = string
    routes       = optional(list(string), [])
    jwt_routes   = optional(list(string), [])
  }))
  description = "Map of service key to NLB listener ARN, public routes, and JWT-authenticated routes."
}
