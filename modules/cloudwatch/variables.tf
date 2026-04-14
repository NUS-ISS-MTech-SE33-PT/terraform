variable "log_group_names" {
  type        = set(string)
  description = "Set of CloudWatch log group names to create."
}

variable "retention_in_days" {
  type        = number
  description = "Number of days to retain log events."
  default     = 7
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all log groups."
  default     = {}
}
