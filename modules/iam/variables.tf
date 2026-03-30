variable "aws_region"        { type = string }
variable "role_name"         { type = string }
variable "tags" {
  type = object({
    environment  = string
    project      = string
    managed_by   = string
  })
}