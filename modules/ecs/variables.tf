variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster."
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the shared ECS task execution role."
}

variable "aws_region" {
  type        = string
  description = "AWS region, used for CloudWatch log configuration."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for ECS tasks."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for ECS tasks."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}

variable "services" {
  type = map(object({
    name               = string
    image              = string
    task_role_arn      = string
    target_group_arn   = string
    log_group_name     = string
    environment        = optional(list(object({ name = string, value = string })), [])
    cpu                = optional(string, "256")
    memory             = optional(string, "512")
    desired_count      = optional(number, 1)
    security_group_ids = optional(list(string), [])
  }))
  description = "Map of service key to Fargate service configuration. security_group_ids overrides the module-level var when set."
}
