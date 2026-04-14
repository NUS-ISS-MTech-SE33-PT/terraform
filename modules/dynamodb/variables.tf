variable "name" {
  type        = string
  description = "DynamoDB table name."
}

variable "hash_key" {
  type        = string
  description = "Attribute name for the partition key."
}

variable "range_key" {
  type        = string
  description = "Attribute name for the sort key. Omit for tables with no sort key."
  default     = null
}

variable "attributes" {
  type = list(object({
    name = string
    type = string
  }))
  description = "List of attribute definitions. Only attributes used as keys (table or GSI) need to be declared."
}

variable "global_secondary_indexes" {
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = optional(string, "ALL")
  }))
  description = "List of GSI definitions."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the table."
  default     = {}
}
