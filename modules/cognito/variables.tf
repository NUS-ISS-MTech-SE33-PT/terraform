variable "aws_region" { type = string }
variable "tags" {
  type = object({
    environment = string
    project     = string
    managed_by  = string
  })
}

variable "android_urls" {
  type = object({
    callback_urls = list(string)
    logout_urls   = list(string)
  })
}

variable "admin_web_urls" {
  type = object({
    callback_urls = list(string)
    logout_urls   = list(string)
  })
}