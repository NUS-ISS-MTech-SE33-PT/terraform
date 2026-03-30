variable "aws_region"        { type = string }
variable "role_name"         { type = string }
variable "tags" {
  type = object({
    env        = string
    project    = string
    managed_by = string
  })
}